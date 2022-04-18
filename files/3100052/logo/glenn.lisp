(defun linka (val x)(rplaca x (cons val x)))
(defun linkd (val x)(rplacd x (cons val x)))
(defun inserta (val x) (rplaca x (cons val (car x))))
(defun insertd (val x) (rplacd x (cons val (cdr x))))
