import os
import sys

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM


slang = sys.argv[1]
tlang = sys.argv[2]

BATCHSIZE = int(os.getenv('BATCHSIZE', 10))
BATCHSIZE = 1

class BatchedMT:
    def __init__(self, tokenizer, model):
        self.buffer_lines = []
        self.model = model
        if torch.cuda.is_available():
            self.model = self.model.cuda()
        self.tokenizer = tokenizer

    def process_line(self, line):
        self.buffer_lines.append(line.strip())
        if len(self.buffer_lines) >= BATCHSIZE:
            self.print_translations()
            self.buffer_lines = []

    def print_translations(self):
        outs = self._do_translate()
        for s in outs:
            print(s)

    def _do_translate(self):
        tokens = self.tokenizer(self.buffer_lines, return_tensors="pt", padding=True)
        if torch.cuda.is_available():
            tokens = {k: v.cuda() for k, v in tokens.items()}
        translated = self.model.generate(**tokens, max_new_tokens=2000)
        return [self.tokenizer.decode(t, skip_special_tokens=True) for t in translated]

    def close(self):
        if len(self.buffer_lines) > 0:
            self.print_translations()
            self.buffer_lines = []


mt = BatchedMT(
    AutoTokenizer.from_pretrained(f"Helsinki-NLP/opus-mt-{slang}-{tlang}"),
    AutoModelForSeq2SeqLM.from_pretrained(f"Helsinki-NLP/opus-mt-{slang}-{tlang}"))
for input_line in sys.stdin:
    mt.process_line(input_line)
mt.close()

