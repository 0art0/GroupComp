import Mathlib

/-!
# Smallest in List: Algorithm with proofs

We illustrate the combination of algorithmic and proof parts in Lean with:

* An algorithm to find the smallest element in a non-empty list of elements of a linearly ordered type.
* A proof that the result of the algorithm is indeed the smallest element in the list.
-/

variable {α : Type}[LinearOrder α]

#check min_eq_right -- ∀ {α : Type u_1} [_inst_1 : linear_order α] {a b : α}, a ≤ b → min a b = a
#check le_of_not_ge -- ∀ {α : Type u} [inst : LinearOrder α] {a b : α}, ¬a ≥ b → a ≤ b
#check List.ne_nil_of_mem -- ∀ {α : Type u_1} {a : α} {l : List α}, a ∈ l → l ≠ []


/-- 
Smallest member of a non-empty list of elements of a linearly ordered type.
-/
def smallest (l: List α)(_: l ≠ []): α := 
  match l with
  | h::t => 
      if c:(t = []) then  
      h else min h (smallest t c)

/--
The result of `smallest` is a member of the list.
-/
theorem smallest_mem (l : List α) (hyp : l ≠ []) : 
  smallest l hyp ∈ l := by
  sorry


/--
The result of `smallest` is `≤` every member of the list.
-/
theorem smallest_le (l : List α) (hyp : l ≠ []) : 
  ∀ a : α, a ∈ l → smallest l hyp ≤ a  := 
  sorry


#eval smallest [3, 4, 2] (by simp)