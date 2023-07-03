import Mathlib
/-!
# Word problem for quotients of ℤ 

## Linear Diophantine Equations

We solve linear diophantine equations of the form `a * x + b * y = c` 
where `a`, `b`, `c` are integers if they have a solution with proof.
Otherwise, we return a proof that there is no solution.

This has a solution if and only if the gcd of `a` and `b` divides `c`.
* If the gcd of `a` and `b` divides `c`, by Bezout's Lemma 
  there are integers `x` and `y` such that `a * x + b * y = gcd a b`.
  Further, as `gcd a b` divides `c`, we have an integer `d` such that 
  `(gcd a b) * d = c`. Then `x * d` and `y * d` are integers
 such that `a * (x * d) + b * (y * d) = c`.
* The converse follows as `gcd a b` divides `a` and `b`, 
  hence `c = a * x + b * y`.

## Corresponding word problem

The existence of solution to the diophantine equation `a * x + b * y = c`
is equivalent to the image of the integer `c` in the the quotient group
`ℤ / {z | ∃ x y : ℤ, a * x + b * y = z}` being trivial, i.e., 
the word problem.

We construct the quotient group and show that the word problem is decidable.
-/

#check Int.gcd_eq_gcd_ab -- ∀ (x y : ℤ), ↑(Int.gcd x y) = x * Int.gcdA x y + y * Int.gcdB x y

#check Int.gcd_dvd_left -- ∀ (i j : ℤ), ↑(Int.gcd i j) ∣ i
#check Int.dvd_mul_right -- ∀ (a b : ℤ), a ∣ a * b
#check dvd_add /-∀ {α : Type u_1} [inst : Add α] [inst_1 : Semigroup α] [inst_2 : LeftDistribClass α] {a b c : α},
  a ∣ b → a ∣ c → a ∣ b + c-/


#check Int.mul_ediv_cancel_of_emod_eq_zero -- ∀ {a b : ℤ}, a % b = 0 → b * (a / b) = a
#check Int.emod_eq_zero_of_dvd -- ∀ {a b : ℤ}, a ∣ b → b % a = 0


/-- If `a * x + b * y = c` has a solution, then `gcd a b` divides `c`.
-/
lemma eqn_solvable_iff_divides_gcd (a b c : ℤ) :
    (∃ x : ℤ, ∃ y : ℤ,  a * x + b * y = c) ↔  ↑(Int.gcd a b) ∣ c := by
    sorry



def spanGroup(a b : ℤ) : AddSubgroup ℤ  where
  carrier := {z | ∃ x y : ℤ, a * x + b * y = z}
  zero_mem' := by 
    sorry
  add_mem' := by
    sorry
  neg_mem' := by
    sorry

abbrev moduloSpan (a b : ℤ) := ℤ ⧸ (spanGroup a b)

abbrev zeroModSpan (a b n : ℤ) : Prop := 
  (QuotientAddGroup.mk n : moduloSpan a b) = (0 : moduloSpan a b)

instance wordProblemMod (a b n : ℤ) : Decidable (zeroModSpan a b n) := by
  simp [moduloSpan, spanGroup, eqn_solvable_iff_divides_gcd]
  apply inferInstance


#eval decide (zeroModSpan 2 3 5) 
