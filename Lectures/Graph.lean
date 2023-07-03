import Mathlib.Data.Bool.Basic
import Mathlib.CategoryTheory.Groupoid
import Mathlib.Algebra.Group.Basic

universe u v

structure Graph (V : Type u) (E : Type v) where
  ι : E → V
  bar : E → E
  bar_involution : ∀ e, bar (bar e) = e
  bar_no_fp : ∀ e, e ≠ bar e

namespace Graph

variable {V : Type u} {E : Type v} (G : Graph V E)
variable {u v w : V}

attribute [simp] bar_involution

def τ (e : E) : V := G.ι (G.bar e)

@[simp] theorem ι_bar (e : E) :  G.ι (G.bar e) = G.τ e := rfl

@[simp] theorem τ_bar (e : E) :  G.τ (G.bar e) = G.ι e := by
  aesop (add norm unfold [τ])

@[ext] structure EdgeBetween (v w : V) where
  edge : E
  source : G.ι edge = v
  target : G.τ edge = w

attribute [aesop safe forward] EdgeBetween.source EdgeBetween.target

variable {G} (e : G.EdgeBetween v w)

def EdgeBetween.bar (e : G.EdgeBetween v w) : G.EdgeBetween w v := 
  { edge := G.bar e.edge
  , source := by aesop
  , target := by aesop
  }

@[simp] theorem EdgeBetween.bar_involution : e.bar.bar = e := by 
    ext; aesop (add norm simp [EdgeBetween.bar])

-- @[aesop unsafe [cases, constructors]]
inductive EdgePath (G : Graph V E) : V → V → Type _ where
  | nil (v) : G.EdgePath v v
  | cons {v w u} : G.EdgeBetween v w → G.EdgePath w u → G.EdgePath v u

namespace EdgePath

def length {v w : V} : G.EdgePath v w → ℕ
  | nil _ => 0
  | cons _ p'  => p'.length.succ

def concat {v w u : V} (p : G.EdgePath v w) (e : G.EdgeBetween w u) : G.EdgePath v u := 
  match p with
  | nil .(v) => cons e (nil u)      
  | cons  e' p'  => cons e' (concat p' e)

@[simp] theorem concat_cons {v w u u': V} (e: G.EdgeBetween v w) (p: G.EdgePath w u) (e': G.EdgeBetween u u')  : 
    concat (cons e p) e' = cons e (concat p e') := by rfl

def reverse {v w : V} (p : G.EdgePath v w) : G.EdgePath w v := 
  match p with
  | nil .(v) => 
      nil v
  | cons  e p  => 
      let tail := reverse p
      concat tail e.bar  

@[simp] theorem reverse_nil {v : V} : 
  reverse (.nil (G := G) v) = .nil (G := G) v := by rfl

theorem reverse_cons {v w u : V} (e : G.EdgeBetween v w) (p : G.EdgePath w u) : 
    reverse (cons e p) = concat (reverse p) e.bar := by rfl

theorem reverse_concat {v w u : V} (p: G.EdgePath v w) (e: G.EdgeBetween w u) : 
    reverse (concat p e) = cons e.bar (reverse p) := by 
    induction p <;> aesop (add norm simp [concat_cons, reverse_cons])

def append { v w u : V}
    (p : G.EdgePath v w) (q : G.EdgePath w u) : G.EdgePath v u :=
  match p with
  | nil .(v) => q
  | cons  e' p'  => 
      let tail := append p' q
      cons e' tail 

instance  G.EdgePath {v w u : V} {G : Graph V E} : 
  HAppend (G.EdgePath v w) (G.EdgePath w u) (G.EdgePath v u) := 
    ⟨append⟩

@[simp] theorem nil_append  {u v : V} (p: G.EdgePath u v) :
  EdgePath.nil (G := G) u ++ p = p := rfl

@[simp] theorem append_nil  {u v : V} (p: G.EdgePath u v) :
  p ++ EdgePath.nil (G := G) v = p := by
    show append _ _ = _
    induction p <;> aesop (add norm simp [append])

@[simp] theorem cons_append {v' v w u : V}
    (e: G.EdgeBetween v' v)(p: G.EdgePath v w)(q: G.EdgePath w u) :
    (cons e p) ++ q = cons e (p ++ q) := by rfl

@[simp] theorem concat_append { v w w' u : V}
    (e : G.EdgeBetween w w')(p: G.EdgePath v w)(q: G.EdgePath w' u) :
    (concat p e) ++ q = p ++ (cons e q) := by
    induction p <;> aesop

theorem append_concat {v w w' u : V} (e : EdgeBetween G w' u)(p: EdgePath G v w)(q: EdgePath G w w') :
  p ++ (concat q e) = concat (p ++ q) e := by
  induction p <;> aesop

theorem concat_eq_append_edge {v w u : V} (e : G.EdgeBetween w u) (p : G.EdgePath v w) :
    p.concat e = p ++ (cons e (nil u)) := by
  have := concat_append e p (.nil _)
  aesop

-- theorem append_cons {v w u u' : V}
--     (p: G.EdgePath v w)(e: G.EdgeBetween w u)(q: G.EdgePath u u') :
--     p ++ (cons e q) = cons e (p ++ q) := by 
--     induction p with
--     | nil  => 
--       rfl
--     | cons  e' p ih =>
--       simp [cons_append, ih]

theorem append_assoc { v w u u' :  V}
  (p: G.EdgePath v w)(q: G.EdgePath w u)(r: G.EdgePath u u') : 
    (p ++ q) ++ r = p ++ (q ++ r) := by 
    induction p <;> aesop

@[simp] theorem reverse_reverse {v w : V} (p : G.EdgePath v w) : 
  p.reverse.reverse = p := by
  induction p <;> aesop (add norm simp [reverse_cons, reverse_concat])

theorem reverse_append {u v w : V} (p : G.EdgePath u v) (q : G.EdgePath v w) :
    (p ++ q).reverse = q.reverse ++ p.reverse := by
  induction p <;>
    aesop (add norm simp [reverse_cons, concat_eq_append_edge, append_assoc])

@[aesop safe [constructors, cases]]
inductive Reduction {v w : V}:
      G.EdgePath v w →  G.EdgePath v w →  Prop where
  | step {u u' : V}(e : G.EdgeBetween u u') (p₁ : G.EdgePath v u) (p₂ : G.EdgePath u w) : 
      Reduction (p₁ ++ (cons e (cons e.bar p₂))) (p₁ ++ p₂)

def reduced  {v w : V} (p : G.EdgePath v w) : Prop := 
  ∀ p', ¬ Reduction p p'

end EdgePath

open EdgePath

abbrev PathClass (G: Graph V E) (v w : V)  := 
    Quot <| @Reduction _ _ G v w

abbrev homotopyClass  {v w : V} (p : G.EdgePath v w) :
   PathClass G v w  := 
  Quot.mk _ p

notation "[[" p "]]" => homotopyClass p

attribute [aesop safe apply] Quot.sound

@[simp] theorem append_cons_bar_cons (e : G.EdgeBetween u u') (p₁ : G.EdgePath v u) (p₂ : G.EdgePath u w) :
    [[p₁ ++ (p₂ |>.cons e.bar |>.cons e)]] = [[p₁ ++ p₂]] := by
  have := Reduction.step e p₁ p₂
  aesop

@[simp] theorem append_cons_cons_bar (e : G.EdgeBetween u' u) (p₁ : G.EdgePath v u) (p₂ : G.EdgePath u w) : 
  [[p₁ ++ (p₂ |>.cons e |>.cons e.bar)]] = [[p₁ ++ p₂]] := by
  have := append_cons_bar_cons e.bar p₁ p₂
  aesop

theorem left_append_step {v w u : V} (a : G.EdgePath v w)  (b₁ b₂ : G.EdgePath w u)  (rel : Reduction  b₁ b₂) : 
   [[a ++ b₁]] = [[a ++ b₂]] := by
    induction rel
    repeat (rw [← append_assoc])
    aesop

theorem right_append_step {v w u : V} (a₁ a₂ : G.EdgePath v w)  (b : G.EdgePath w u) (rel : Reduction  a₁ a₂) : 
    [[a₁ ++ b]] = [[a₂ ++ b]] := by
  aesop (add norm simp [append_assoc])

theorem reverse_step {v w : V} (a₁ a₂ : G.EdgePath v w) (rel : Reduction a₁ a₂) :
    [[a₁.reverse]] = [[a₂.reverse]] := by
  induction rel
  aesop (add norm simp [reverse_append, reverse_cons])

@[simp] theorem reverse_left_inverse {v w : V} 
(p : G.EdgePath v w) : 
    [[p.reverse ++ p]] = [[.nil w]] := by
    induction p <;>
      aesop (add norm simp [reverse_cons, reverse_concat, cons_append])

@[simp] theorem reverse_right_inverse {v w : V} (p : G.EdgePath w v) :
    [[p ++ p.reverse]] = [[.nil w]] := by
  have := reverse_left_inverse p.reverse
  aesop

namespace PathClass

@[aesop norm unfold] 
protected def id {G : Graph V E} (v : V) : G.PathClass v v :=
  [[.nil v]]

def mul {v w u : V} : 
    G.PathClass v w → G.PathClass w u → G.PathClass v u := by
  apply Quot.lift₂ (fun p₁ p₂ ↦ [[ p₁ ++ p₂ ]]) <;>
    aesop (add safe apply [left_append_step, right_append_step])

@[aesop norm unfold] def inv {u v : V} : G.PathClass u v → G.PathClass v u := 
  Quot.lift ([[·.reverse]]) reverse_step

@[simp] theorem mul_paths (p : G.EdgePath u v) (p' : G.EdgePath v w) :
  mul [[p]] [[p']] = [[p ++ p']] := rfl

@[simp] theorem id_mul  {u v : V} : ∀ p : G.PathClass u v, 
  mul (.id u) p = p := by
    apply Quot.ind; aesop

@[simp] theorem mul_id  {u v : V} : ∀ p : G.PathClass u v,
  mul p (.id v) = p := by 
    apply Quot.ind; aesop

@[simp] theorem inv_mul {u v : V} : ∀ p : G.PathClass u v,
    mul p.inv p = .id v := by
  apply Quot.ind; aesop

@[simp] theorem mul_inv {u v : V} : ∀ p : G.PathClass u v,
    mul p p.inv = .id u := by
  apply Quot.ind; aesop

theorem mul_assoc { v w u u' :  V}:
  (p: PathClass G v w) → (q: PathClass G w u) → (r: PathClass G u u') →  
    mul (mul p q) r = mul p (mul q r) := by
    apply Quot.ind
    intro a
    apply Quot.ind
    intro b
    apply Quot.ind
    intro c
    simp [append_assoc]

theorem append_mul {v w u : V} (p : EdgePath G v w) (q : EdgePath G w u) : 
    [[p ++ q]] = mul [[ p ]] [[ q]] := by rfl

theorem cons_natural{G: Graph V E}{v w u : V} (a : EdgeBetween G v w)  (b₁ b₂ : EdgePath G w u) : [[b₁]] = [[b₂]] → 
   [[cons a  b₁]] = [[cons a b₂]] := by
  intro rel
  rw [show cons a b₁ = cons a (nil _) ++ b₁ by rfl, 
      show cons a b₂ = cons a (nil _) ++ b₂ by rfl,
      append_mul, append_mul, rel]

theorem concat_natural {G: Graph V E}{v w u : V} (a₁ a₂ : EdgePath G v w)  (b : EdgeBetween G w u) : [[a₁]] = [[a₂]] → 
   [[concat a₁ b]] = [[concat a₂ b]] := by
  intro rel
  have: concat a₁  b = a₁ ++ (concat (nil _) b) := by 
    rw [append_concat, append_nil]
  rw [this]
  have: concat a₂  b = a₂ ++ (concat (nil _) b) := by 
    rw [append_concat, append_nil]
  rw [this, append_mul, append_mul, rel]

end PathClass

open PathClass

@[instance]
def FundamentalGroupoid : CategoryTheory.Groupoid V where
  Hom := G.PathClass
  id := .id
  comp := .mul (G := G)
  id_comp := id_mul
  comp_id := mul_id
  assoc := mul_assoc
  inv := inv
  inv_comp := inv_mul
  comp_inv := mul_inv

def wedgeCircles (S: Type) : Graph Unit (S × Bool) := {
  ι := fun _ ↦ ()
  bar := fun (e, b) ↦ (e, !b)
  bar_involution := by aesop
  bar_no_fp := by aesop
}

class ConnectedGraph (G: Graph V E) where
  path : (v w: V) → G.EdgePath v w

def getPath (G: Graph V E) [ConnectedGraph G] (v w: V) : G.EdgePath v w :=
  ConnectedGraph.path v w

@[ext] structure Morphism (G₁ : Graph V₁ E₁) (G₂ : Graph V₂ E₂) where
  vertexMap : V₁ → V₂
  edgeMap : E₁ → E₂
  commutes : ∀ (e : E₁), G₂.ι (edgeMap e) = vertexMap (G₁.ι e)
  bar_commutes : ∀ (e : E₁), edgeMap (G₁.bar e) = G₂.bar (edgeMap e)

theorem morphism_init_commutes {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂} 
    (f: Morphism G₁ G₂) : 
      ∀ (e : E₁), G₂.ι (f.edgeMap e) = f.vertexMap (G₁.ι e) := by
  intro e
  exact f.commutes e

theorem morphism_bar_commutes {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂} 
    (f: Morphism G₁ G₂) : 
      ∀ (e : E₁), f.edgeMap (G₁.bar e) = G₂.bar (f.edgeMap e) := by
  intro e
  exact f.bar_commutes e

theorem morphism_term_commutes {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂} 
    (f: Morphism G₁ G₂) : 
      ∀ (e : E₁), G₂.τ (f.edgeMap e) = f.vertexMap (G₁.τ e) := by
  intro e
  rw [Graph.τ, Graph.τ, ←morphism_bar_commutes, ←morphism_init_commutes]



structure CoveringMap (G₁ : Graph V₁ E₁) (G₂ : Graph V₂ E₂) 
      extends Morphism G₁ G₂ where
  localSection : (v₁ : V₁) → (e :E₂) → 
      vertexMap v₁ = G₂.ι e   → E₁
  section_init : (v₁ : V₁) → (e₂ : E₂) → 
    (h : vertexMap v₁ = G₂.ι e₂) → 
    G₁.ι (localSection v₁ e₂ h) = v₁ 
  left_inverse : (v₁ : V₁) → (e₂ :E₂) → 
    (h : vertexMap v₁ = G₂.ι e₂) → 
    edgeMap (localSection v₁ e₂ h) = e₂
  right_inverse : (v₁ : V₁) → (e₁ : E₁) →
    (h : vertexMap v₁ = G₂.ι (edgeMap e₁)) →  
    localSection v₁ (edgeMap e₁) h = e₁ 

/--
Path lifting function. 
-/
def pathLift' (G₁ : Graph V₁ E₁) (G₂ : Graph V₂ E₂)
    (p : CoveringMap G₁ G₂) (v₁: V₁) (v₂ w₂ : V₂)
    (h : p.vertexMap v₁ = v₂)(e: EdgePath G₂ v₂ w₂) : 
      {pair : Σ w₁ : V₁, EdgePath G₁ v₁ w₁ // 
        p.vertexMap pair.fst = w₂} := by
    match e with
    | nil _ => exact ⟨⟨v₁, nil _⟩, h⟩
    | cons e₂ b₂ =>
      rename_i w₂' w₂''
      let e₁ := p.localSection v₁ e₂.edge (by rw [h, e₂.source]) 
        -- lift of the edge
      let v₁' := G₁.τ e₁ -- the final vertex of the lift
      have init_vert : G₁.ι e₁ = v₁ := by apply p.section_init
      have term_vert : p.vertexMap (G₁.τ e₁) = w₂'' := by
        rw [← e₂.target]
        rw [←morphism_term_commutes ]
        congr
        apply p.left_inverse
      let ⟨⟨w₁, tail⟩, pf⟩ := pathLift' G₁ G₂ p v₁' w₂'' w₂ term_vert b₂
      let edge₁ : EdgeBetween G₁ v₁ v₁' :=
        ⟨e₁, init_vert, rfl⟩
      exact ⟨⟨w₁, EdgePath.cons edge₁ tail⟩, pf⟩


def EdgePath.toEdgeList {G : Graph V E} {v w : V} (p : EdgePath G v w) : 
  List E := 
  match p with
  | nil _ => []
  | cons e p' =>  e.edge :: p'.toEdgeList

theorem nil_edgeList {G : Graph V E} {v : V}  : 
  (nil v : EdgePath G v v).toEdgeList = [] := rfl

theorem cons_edgeList {G: Graph V E} {v w u: V} (e : EdgeBetween G v w) 
    (p : EdgePath G w u) : 
  (cons e p).toEdgeList = e.edge :: p.toEdgeList := rfl


theorem cons_eq {G: Graph V E} {v w w' u: V} (e : EdgeBetween G v w) 
    (e' : EdgeBetween G v w' )(p : EdgePath G w u) (p' : EdgePath G w' u) (eq₁ : e.edge = e'.edge) (eq₂ : w = w') (eq₃ :  p = eq₂ ▸  p'): 
      cons e' p' = cons e p := by 
      match p, p', e, e', eq₂ with
      | p, p', e, e', rfl => 
        simp [cons_edgeList,  eq₃]
        ext
        symm
        assumption

theorem cons_eq' {G: Graph V E} {v w w' u: V} (e : EdgeBetween G v w) 
    (e' : EdgeBetween G v w' )(p : EdgePath G w u) (p' : EdgePath G w' u) (eq₁ : e.edge = e'.edge) (eq₂ : w' = w) (eq₃ : eq₂ ▸ p =   p'): 
      cons e' p' = cons e p := by 
      match p, p', e, e', eq₂ with
      | p, p', e, e', rfl => 
        simp [cons_edgeList, Eq.symm eq₃]
        ext
        symm
        assumption

theorem edgeList_cast_init {G: Graph V E} {v v' w : V}  
    (p : EdgePath G v w)(eqn : v = v'):
      p.toEdgeList = (eqn ▸ p).toEdgeList := by
      match p, eqn with
      | p, rfl => rfl

theorem edgeList_cast_term {G: Graph V E} {v w w' : V}  
    (p : EdgePath G v w)(eqn : w = w'):
      p.toEdgeList = (eqn ▸ p).toEdgeList := by
      match p, eqn with
      | p, rfl => rfl

@[ext] theorem eq_of_edgeList_eq {G: Graph V E}{v w: V}
  (p₁ p₂ : EdgePath G v w) : p₁.toEdgeList = p₂.toEdgeList → p₁ = p₂ := by
  induction p₁ with
  | nil v =>
    match p₂ with
    | EdgePath.nil v => 
      intro h
      rw [nil_edgeList] at h      
    | EdgePath.cons e₂ p₂  =>
      intro h
      simp [cons_edgeList, nil_edgeList] at h
  | cons e₁ p₁' ih =>
    intro h
    induction p₂ with
    | nil w =>
      simp [cons_edgeList, nil_edgeList] at h
    | cons e₂ p₂'  =>
      simp [cons_edgeList] at h
      have e1t := e₁.target
      have e2t := e₂.target
      rw [h.1] at e1t
      rw [e1t] at e2t
      simp [h.2] at ih 
      apply cons_eq' 
      · symm
        exact h.1
      · let step := ih (e2t ▸ p₂') 
        symm   
        have : p₁' = (e2t ▸ p₂')  := by
          apply step
          exact edgeList_cast_init p₂' (Eq.symm e2t)
        rw [this]
        · simp
          assumption
        
theorem term_eq_of_edgeList_eq {G: Graph V E}{v₁ v₂ w₁ w₂: V}
  (p₁ : EdgePath G v₁ w₁) (p₂ : EdgePath G v₂ w₂) : p₁.toEdgeList = p₂.toEdgeList → (v₁ = v₂) → (w₁ = w₂)  := by 
  induction p₁ with
  | nil v₁' =>
    match p₂ with
    | EdgePath.nil v => 
      intro h heq
      rw [nil_edgeList] at h      
      exact heq
    | EdgePath.cons e₂ p₂  =>
      intro h
      simp [cons_edgeList, nil_edgeList] at h
  | cons e p₁' ih =>    
    intro h heq
    match p₂ with
    | EdgePath.nil w =>
      simp [cons_edgeList, nil_edgeList] at h
    | EdgePath.cons e₂ p₂' =>
      simp [cons_edgeList] at h
      apply term_eq_of_edgeList_eq p₁' p₂' h.right
      rw [←e₂.target, ←e.target, h.left]


@[ext]
structure PathLift {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (p : CoveringMap G₁ G₂) (v₁: V₁) (v₂ w₂ : V₂)
    (h : p.vertexMap v₁ = v₂)(e: EdgePath G₂ v₂ w₂) where
  w₁ : V₁ 
  path: EdgePath G₁ v₁ w₁
  h' : p.vertexMap w₁ = w₂
  list_commutes : path.toEdgeList.map p.edgeMap = e.toEdgeList

def pathLift {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (p : CoveringMap G₁ G₂) (v₁: V₁) (v₂ w₂ : V₂)
    (h : p.vertexMap v₁ = v₂)(e: EdgePath G₂ v₂ w₂):
    PathLift p v₁ v₂ w₂ h e := by
    match e with
    | nil _ => exact ⟨v₁, nil _, h, (by simp [toEdgeList])⟩
    | cons e₂ b₂ =>
      rename_i w₂' w₂''
      let e₁ := p.localSection v₁ e₂.edge (by rw [h, e₂.source]) 
        -- lift of the edge
      let v₁' := G₁.τ e₁ -- the final vertex of the lift
      have init_vert : G₁.ι e₁ = v₁ := by apply p.section_init
      have term_vert : p.vertexMap (G₁.τ e₁) = w₂'' := by
        rw [← e₂.target]
        rw [←morphism_term_commutes ]
        congr
        apply p.left_inverse
      let ⟨w₁, tail, pf₁, pf₂⟩ := pathLift  p v₁' w₂'' w₂ term_vert b₂
      let edge₁ : EdgeBetween G₁ v₁ v₁' :=
        ⟨e₁, init_vert, rfl⟩
      exact ⟨w₁, cons edge₁ tail, pf₁, by 
        simp [cons_edgeList, pf₂]
        apply p.left_inverse⟩

def Morphism.pathMapAux {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (f: Morphism G₁ G₂) (v₁ w₁: V₁) (p: G₁.EdgePath v₁ w₁)
    (v₂ w₂ : V₂)(hv : f.vertexMap v₁ = v₂)(hw : f.vertexMap w₁ = w₂) : 
      {path : G₂.EdgePath v₂ w₂ // path.toEdgeList = p.toEdgeList.map f.edgeMap} := by 
      match p with
      | nil _ =>
        rw [←hw, hv]
        exact ⟨nil _, by simp [nil_edgeList]⟩
      | cons e p' => 
        rename_i w₁' w₁'' u'
        let e₁ := f.edgeMap e.edge
        let init_vert : G₂.ι e₁ = v₂ := by
          rw [←hv, ←e.source, ←morphism_init_commutes] 
        let term_vert : G₂.τ e₁ = f.vertexMap u' := by
          rw [morphism_term_commutes, e.target]
        let edge₂ : EdgeBetween G₂ v₂ (f.vertexMap u') :=
          ⟨e₁, init_vert, term_vert⟩
        let ⟨tail, ih⟩ := pathMapAux f u' w₁ p' (f.vertexMap u') w₂ rfl hw
        exact ⟨cons edge₂ tail, by simp [cons_edgeList, ih]⟩ 

def Morphism.pathMap {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (f: Morphism G₁ G₂) (v₁ w₁: V₁) (p: G₁.EdgePath v₁ w₁)
    (v₂ w₂ : V₂)(hv : f.vertexMap v₁ = v₂)(hw : f.vertexMap w₁ = w₂) :=
      (pathMapAux f v₁ w₁ p v₂ w₂ hv hw).val

theorem pathMap_toList {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (f: Morphism G₁ G₂) (v₁ w₁: V₁) (p: G₁.EdgePath v₁ w₁)
    (v₂ w₂ : V₂)(hv : f.vertexMap v₁ = v₂)(hw : f.vertexMap w₁ = w₂) :
      (f.pathMap v₁ w₁ p v₂ w₂ hv hw).toEdgeList = p.toEdgeList.map f.edgeMap := 
      (f.pathMapAux  v₁ w₁ p v₂ w₂ hv hw).property


theorem PathLift.commutes {G₁ : Graph V₁ E₁} {G₂ : Graph V₂ E₂}
    (p : CoveringMap G₁ G₂) (v₁: V₁) (v₂ w₂ : V₂)
    (h : p.vertexMap v₁ = v₂)(e: EdgePath G₂ v₂ w₂) 
    (lift : PathLift p v₁ v₂ w₂ h e) :
    p.pathMap v₁ lift.w₁ lift.path v₂ w₂ h lift.h' = e := by
      apply eq_of_edgeList_eq
      rw [pathMap_toList, lift.list_commutes]      

end Graph