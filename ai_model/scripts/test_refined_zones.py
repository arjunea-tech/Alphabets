import sys
import numpy as np
from test_engine_simulation import mockStrokesA, mockStrokesDa, mockStrokesAa, run_dart_engine

# Test with refined aa_tail zone: x in [25..31], y in [24..31]
def test_refined_zones():
    from test_engine_simulation import preprocess_strokes_to_image, smooth32x32, raw_fields, tight_fields, wide_fields, norm_fields, actives, templates
    
    def evaluate(strokes, expected_char):
        raw_tensor = preprocess_strokes_to_image(strokes, canvas_size=(350, 350), target_size=(32, 32))
        u_tight = smooth32x32(raw_tensor, 1)
        norm_u = np.linalg.norm(u_tight)
        u_norm = u_tight / norm_u if norm_u > 0 else u_tight
        u_active = (raw_tensor > 0.15).sum()

        candidates = []
        for label in templates:
            t_raw = raw_fields[label]
            t_tight = tight_fields[label]
            t_wide = wide_fields[label]
            t_norm = norm_fields[label]
            t_active = actives[label]

            field_sim = float(np.sum(u_norm * t_norm))
            u_valid = float(((raw_tensor > 0.15) & (t_wide > 0.08)).sum())
            prec = u_valid / u_active if u_active > 0 else 0
            
            t_covered = float(((t_raw > 0.15) & (u_tight > 0.08)).sum())
            rec = t_covered / t_active if t_active > 0 else 0
            
            intersection = float(((raw_tensor > 0.15) & (t_raw > 0.15)).sum())
            union = float(u_active + t_active - intersection)
            iou = intersection / union if union > 0 else 0
            f1 = (2 * prec * rec) / (prec + rec) if (prec + rec) > 0 else 0
            density_ratio = min(u_active / t_active, t_active / u_active) if t_active > 0 and u_active > 0 else 0
            
            cov_gate = min(1.0, max(0.0, (rec - 0.10) / 0.25))
            prec_gate = min(1.0, max(0.0, (prec - 0.10) / 0.25))
            
            score = (0.35 * field_sim + 0.30 * f1 + 0.20 * min(1.0, iou * 2.0) + 0.15 * density_ratio) * cov_gate * prec_gate
            candidates.append((label, score, prec, rec))

        # Refined spatial feature counts
        aa_tail = int((raw_tensor[24:32, 24:32] > 0.15).sum())
        oo_la = int((raw_tensor[0:15, 18:32] > 0.15).sum())
        au_la = int((raw_tensor[:, 20:32] > 0.15).sum())
        i_curl = int((raw_tensor[18:32, 0:16] > 0.15).sum())

        adj_candidates = []
        for label, s, prec, rec in candidates:
            score = s
            if label == "அ" and aa_tail >= 5: score *= 0.30
            if label == "ஆ" and aa_tail < 3: score *= 0.40
            if label == "உ" and oo_la >= 8: score *= 0.30
            if label == "ஊ" and oo_la < 4: score *= 0.35
            if label == "ஒ" and au_la >= 14: score *= 0.30
            if label == "ஔ" and au_la < 8: score *= 0.35
            if label == "ஆ" and i_curl >= 18 and aa_tail < 3: score *= 0.30
            adj_candidates.append((label, score, prec, rec))

        adj_candidates.sort(key=lambda x: x[1], reverse=True)
        top1 = adj_candidates[0]
        exp = next(x for x in adj_candidates if x[0] == expected_char)
        
        is_winner = (top1[0] == expected_char)
        is_match = is_winner and exp[1] >= 0.35 and exp[3] >= 0.25 and exp[2] >= 0.28
        return is_match, top1[0], exp[1], exp[2], exp[3]

    print("1. 'mockStrokesA' when expecting 'அ':", evaluate(mockStrokesA, "அ"))
    print("2. 'mockStrokesDa' (ட) when expecting 'அ':", evaluate(mockStrokesDa, "அ"))
    print("3. 'mockStrokesAa' (ஆ) when expecting 'அ':", evaluate(mockStrokesAa, "அ"))

test_refined_zones()
