import argparse
import math
import os
import random
import time
import sys
import torch

import numpy as np

from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from transformers.utils import logging as hf_logging

hf_logging.disable_progress_bar()

#
# Command line arguments
#
parser = argparse.ArgumentParser()

parser.add_argument("--model", required=True)
parser.add_argument("--prompt", required=True)
parser.add_argument("--bits", required=True, type=int)
parser.add_argument("--tokens", required=True, type=int)

args = parser.parse_args()

model_name = args.model
prompt = args.prompt
max_tokens = args.tokens

if args.bits == 4:
    quant_conf = BitsAndBytesConfig(load_in_4bit=True)
elif args.bits == 8:
    quant_conf = BitsAndBytesConfig(load_in_8bit=True)
else:
    print("Invalid bits value. Must be 4 or 8")
    sys.exit(1)

#
# Increase determinism
#
torch.use_deterministic_algorithms(True)
torch.backends.cudnn.benchmark = False
torch.backends.cudnn.deterministic = True
seed = 0
random.seed(seed)
np.random.seed(seed)
torch.manual_seed(seed)
torch.cuda.manual_seed_all(seed)

gen_kwargs = dict(
    max_new_tokens=max_tokens,
    do_sample=False,
    temperature = None, # Supress warnings. These are not
    top_p = None,       # relevant when do_sample=False.
    num_beams=1,
)

#
# Tokenize prompt
#
tokenizer = AutoTokenizer.from_pretrained(model_name)

if tokenizer.pad_token_id is None:
    tokenizer.pad_token = tokenizer.eos_token

prompt_inputs = tokenizer(prompt, return_tensors="pt").to("cuda")
prompt_len = prompt_inputs["input_ids"].shape[1]

#
# Load unquantized model
#
unquantized = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    dtype=torch.float16,
)
unquantized.eval()

#
# Generate reference tokens with unquantized model
#
with torch.inference_mode():
    t0 = time.time()
    unquantized_out = unquantized.generate(prompt_inputs["input_ids"], **gen_kwargs)
    t1 = time.time()

unquantized_text = tokenizer.decode(unquantized_out[0], skip_special_tokens=True)
new_tokens = unquantized_out.shape[1] - prompt_len

print("===== UNQUANTIZED OUTPUT =====")
print(unquantized_text)
print(f"Unquantized generation time: {t1 - t0:.2f}s")
print(f"Unquantized tokens/sec: {new_tokens / max(t1 - t0, 1e-9):.2f}")

#
# Split prompt and completion tokens
#
unquantized_out = unquantized_out[0]
completion_ids = unquantized_out[prompt_len:]

#
# Load quantized model
#

quantized = AutoModelForCausalLM.from_pretrained(
    model_name,
    device_map="auto",
    quantization_config=quant_conf,
    dtype=torch.float16,
)
quantized.eval()

#
# Generate with quantized model (sanity check only)
#
with torch.inference_mode():
    t0 = time.time()
    quantized_out = quantized.generate(prompt_inputs["input_ids"], **gen_kwargs)
    t1 = time.time()

quantized_text = tokenizer.decode(quantized_out[0], skip_special_tokens=True)
new_tokens = quantized_out.shape[1] - prompt_len

print("DEGBUG:", quantized_out)
print("\n===== QUANTIZED OUTPUT (sanity check only) =====")
print(quantized_text)
print(f"Quantized generation time: {t1 - t0:.2f}s")
print(f"Quantized tokens/sec: {new_tokens / max(t1 - t0, 1e-9):.2f}")

#
# Calculate perplexity for quantized generation on unquantized reference
#

# Build reference sequence = unquantized prompt + completion
ref_input_ids = unquantized_out.unsqueeze(0).to("cuda")
ref_attention_mask = torch.ones_like(ref_input_ids)

# Mask prompt tokens to only covers completion
labels = ref_input_ids.clone()
labels[:, :prompt_len] = -100

with torch.inference_mode():
    out = quantized(
        input_ids=ref_input_ids,
        attention_mask=ref_attention_mask,
        labels=labels,
    )
    loss = out.loss
    ppl = math.exp(loss.item())

print("\n===== QUANTIZED GENERATION VALIDATION =====")
print(f"Completion tokens: {completion_ids.numel()}")
print(f"Cross-entropy loss: {loss.item():.6f}")
print(f"Perplexity: {ppl:.4f}")

def model_param_size_gb(model):
    total = 0
    for p in model.parameters():
        total += p.numel() * p.element_size()
    return total / 1024**3

print(f"Unquantized param size: {model_param_size_gb(unquantized):.2f} GB")
print(f"Quantized param size: {model_param_size_gb(quantized):.2f} GB")



