(import pytest
        [dataclasses [dataclass]]
        [hy.errors [HySyntaxError]])

(defn test-pattern-matching []
  (assert (is (match 0
                     0 :if False False
                     0 :if True True)
              True))
  (assert (is (match 0
                     0 True
                     0 False)
              True))

  (assert (is (match 2 (| 0 1 2 3) True)
              True))

  (assert (is (match 4 (| 0 1 2 3) True)
              None))

  (assert (is (match 1) None))

  (defclass A []
    (setv B 0))
  (setv z
        (match 0
               x :if x 0
               _ :as y :if (and (= y x) y) 1
               A.B 2
               (. A B) 2))
  (assert (= A.B 0))
  (assert (= z 2))

  (assert (= 0 (match (,) [] 0)))
  (assert (= [0 [0 1 2]] (match (, 0 1 2) [#* x] [0 x])))
  (assert (= [2] (match [0 1 2] [0 1 #* x] x)))
  (assert (= [0 1] (match [0 1 2] [#* x 2] x)))
  (assert (= 5 (match {"hello" 5} {"hello" x} x)))
  (assert (= :as (match 1 1 :if True ':as)))
  (assert (is (match {}
                     {0 [1 2 {}]} 0
                     {0 [1 2 {}] 1 [[]]} 1
                     [] 2)
              None))

  (assert (= 1 (match {0 0}
                      {0 [ 1 2 {}]} 0
                      (| {0 (| [1 2 {}] False)}
                          {1 [[]]}
                          {0 [1 2 {}]}
                          []
                          "X"
                          {})
                       1
                      [] 2)))
  (assert (is (match [0 0] (| [0 1] [1 0]) 0)
              None))

  (setv x #{0})
  (assert (is (match x [0] 0) None))
  (assert (= x (match x (set z) z)))


  (assert (= (match [0 1 2]
                    [0 #* x] :as z :if (as-> z $ (+ $ [3]) (len $) (= $ 4)) 0)
             0))

  (with-decorator
    dataclass
    (defclass Point []
      (^int x)
      (^int y)))

  (assert (= 0 (match (Point 1 0) (Point 1 :y var) var)))
  (assert (is None (match (Point 0 0) (Point 1 :y var) var)))

  (setv match-check [])
  (match 1
         1 :if (do (match-check.append 1) False) (match-check.append 2)
         1 :if False (match-check.append 3)
         _ :if (do (match-check.append 4) True) (match-check.append 5))
  (assert (= match-check [1 4 5]))

  (defn whereis [points]
    (match points
           [] "No points"
           [(Point 0 0)] "The origin"
           [(Point x y)] f"Single point {x}, {y}"
           [(Point 0 y1) (Point 0 y2)] f"Two on the Y axis at {y1}, {y2}"
           _ "Something else"))
  (assert (= (whereis []) "No points"))
  (assert (= (whereis [(Point 0 0)]) "The origin"))
  (assert (= (whereis [(Point 0 1)]) "Single point 0, 1"))
  (assert (= (whereis [(Point 0 0) (Point 0 0)]) "Two on the Y axis at 0, 0"))
  (assert (= (whereis [(Point 0 1) (Point 0 1)]) "Two on the Y axis at 1, 1"))
  (assert (= (whereis [(Point 0 1) (Point 1 0)]) "Something else"))
  (assert (= (whereis 42) "Something else"))

  (assert (= [42 [1 2 3]]
             (match {"something" {"important" 42}
                     "some list" [[1 2 3]]}
                    {"something" {"important" a} "some list" [b]} [a b])))

  (assert (= [-1 0 1 2 (Point 1 2) [(Point -1 0) (Point 1 2)]]
             (match [(Point -1 0) (Point 1 2)]

                    (, (Point x1 y1) (Point x2 y2) :as p2) :as whole
                    [x1 y1 x2 y2 p2 whole])))
  (assert (= (match [1 2 3]
                    x x)
             [1 2 3]))

  ;; `print` is not a MatchClass type
  (with [(pytest.raises TypeError)] (hy.eval '(match [] (print 1 1) 1)))
  ;; key of MatchMapping can only be a literal
  (with [(pytest.raises HySyntaxError)] (hy.eval '(match {} {x 1} 1)))
  ;; :as clause cannot come after :if guard
  (with [(pytest.raises HySyntaxError)]
    (hy.eval '(match 1
                     1 :if True :as x x))))
