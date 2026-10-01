import sys
import numpy as np

def apply_discriminative_guards(scores, raw_tensor):
    # raw_tensor is [32, 32]
    # Count pixels in key spatial zones
    dim = 32
    
    # 1. 'ஆ' tail zone: x in [20, 31], y in [22, 31]
    aa_tail_pixels = int((raw_tensor[22:32, 20:32] > 0.15).sum())
    
    # 2. 'ஊ' top-right zone: x in [16, 31], y in [0, 16]
    oo_la_pixels = int((raw_tensor[0:16, 16:32] > 0.15).sum())
    
    # 3. 'ஔ' right column zone: x in [18, 31]
    au_la_pixels = int((raw_tensor[:, 18:32] > 0.15).sum())
    
    # 4. 'இ' bottom-left / center curl zone: x in [0, 18], y in [16, 31]
    i_curl_pixels = int((raw_tensor[16:32, 0:18] > 0.15).sum())

    # Apply guards
    adjusted = dict(scores)
    
    # If user drew 'ஆ' tail: penalize 'அ'
    if aa_tail_pixels >= 6 and "அ" in adjusted:
        adjusted["அ"] *= 0.30
        
    # If expected 'ஆ' but tail is missing: penalize 'ஆ'
    if aa_tail_pixels < 4 and "ஆ" in adjusted:
        adjusted["ஆ"] *= 0.40
        
    # If user drew 'ள' in top-right: penalize 'உ'
    if oo_la_pixels >= 8 and "உ" in adjusted:
        adjusted["உ"] *= 0.30
        
    # If expected 'ஊ' but 'ள' is missing: penalize 'ஊ'
    if oo_la_pixels < 5 and "ஊ" in adjusted:
        adjusted["ஊ"] *= 0.35
        
    # If user drew 'ள' on right: penalize 'ஒ'
    if au_la_pixels >= 15 and "ஒ" in adjusted:
        adjusted["ஒ"] *= 0.30
        
    # If expected 'ஔ' but 'ள' on right is missing: penalize 'ஔ'
    if au_la_pixels < 10 and "ஔ" in adjusted:
        adjusted["ஔ"] *= 0.35

    # If user drew 'இ' (strong center/bottom-left curl) but tested for 'ஆ': penalize 'ஆ'
    if i_curl_pixels >= 18 and aa_tail_pixels < 5 and "ஆ" in adjusted:
        adjusted["ஆ"] *= 0.30

    return adjusted

print("Discriminative guards defined successfully.")
