;
; unordered-odo-equal.scm
;
; Multiple unordered links, arragned in series (so that the odometer
; runs) but then constrained so that neighboring terms must be
; identical.  This sharply limits the possible orderings.
; See also unordered-odo-couple.scm for same test case, but with
; direct constraints.
;
(use-modules (opencog) (opencog exec))

(Evaluation (Predicate "equal") (List (Concept "L") (Concept "L")))
(Evaluation (Predicate "equal") (List (Concept "M") (Concept "M")))
(Evaluation (Predicate "equal") (List (Concept "N") (Concept "N")))
(Evaluation (Predicate "equal") (List (Concept "P") (Concept "P")))
(Evaluation (Predicate "equal") (List (Concept "Q") (Concept "Q")))
(Evaluation (Predicate "equal") (List (Concept "R") (Concept "R")))
(Evaluation (Predicate "equal") (List (Concept "S") (Concept "S")))
(Evaluation (Predicate "equal") (List (Concept "T") (Concept "T")))
(Evaluation (Predicate "equal") (List (Concept "U") (Concept "U")))
(Evaluation (Predicate "equal") (List (Concept "V") (Concept "V")))
(Evaluation (Predicate "equal") (List (Concept "W") (Concept "W")))
(Evaluation (Predicate "equal") (List (Concept "X") (Concept "X")))
(Evaluation (Predicate "equal") (List (Concept "Y") (Concept "Y")))
(Evaluation (Predicate "equal") (List (Concept "Z") (Concept "Z")))

; ----------------------------------------------------
; Coupled sets, expect 2! * 2! = 4 permutations

(List (Concept "B")
	(Set (Concept "P") (Concept "Q") (Concept "R"))
	(Set (Concept "R") (Concept "S") (Concept "T")))

(define equ-dim-two
	(Bind
		(And
			(Present (List (Variable "$CPT")
				(Set (Variable "$U") (Variable "$V") (Variable "$W"))
				(Set (Variable "$X") (Variable "$Y") (Variable "$Z"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$W") (Variable "$X")))))
		(Associative
			(Variable "$U") (Variable "$V") (Variable "$W")
			(Variable "$X") (Variable "$Y") (Variable "$Z"))))

; (cog-execute! equ-dim-two)

; ----------------------------------------------------
; Like above, but 2! * 1! * 2! = 4 permutations

(List (Concept "C")
	(Set (Concept "P") (Concept "Q") (Concept "R"))
	(Set (Concept "R") (Concept "S") (Concept "T"))
	(Set (Concept "T") (Concept "U") (Concept "V")))

(define equ-dim-three
	(Bind
		(And
			(Present (List (Variable "$CPT")
				(Set (Variable "$A") (Variable "$B") (Variable "$C"))
				(Set (Variable "$U") (Variable "$V") (Variable "$W"))
				(Set (Variable "$X") (Variable "$Y") (Variable "$Z"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$C") (Variable "$U"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$W") (Variable "$X")))))
		(Associative
			(Variable "$A") (Variable "$B") (Variable "$C")
			(Variable "$U") (Variable "$V") (Variable "$W")
			(Variable "$X") (Variable "$Y") (Variable "$Z"))))

; (cog-execute! equ-dim-three)

; ----------------------------------------------------
; Like above, but 2*1*1*2 = 4 permutations

(List (Concept "D")
   (Set (Predicate "P") (Predicate "Q") (Predicate "R"))
   (Set (Predicate "R") (Predicate "S") (Predicate "T"))
   (Set (Predicate "T") (Predicate "U") (Predicate "V"))
   (Set (Predicate "V") (Predicate "W") (Predicate "X")))

(define equ-dim-four
	(Bind
		(And
			(Present (List (Variable "$CPT")
				(Set (Variable "$A") (Variable "$B") (Variable "$C"))
				(Set (Variable "$D") (Variable "$E") (Variable "$F"))
				(Set (Variable "$U") (Variable "$V") (Variable "$W"))
				(Set (Variable "$X") (Variable "$Y") (Variable "$Z"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$C") (Variable "$D"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$F") (Variable "$U"))))
			(Present (Evaluation (Predicate "equal")
				(List (Variable "$W") (Variable "$X")))))
		(Associative
			(Variable "$A") (Variable "$B") (Variable "$C")
			(Variable "$D") (Variable "$E") (Variable "$F")
			(Variable "$U") (Variable "$V") (Variable "$W")
			(Variable "$X") (Variable "$Y") (Variable "$Z"))))

; (cog-execute! equ-dim-four)

; ----------------------------------------------------
