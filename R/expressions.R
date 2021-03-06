#'
#' The Expression class.
#'
#' This class represents a mathematical expression.
#'
#' @name Expression-class
#' @aliases Expression
#' @rdname Expression-class
Expression <- setClass("Expression", contains = "Canonical")

setOldClass("data.frame")
setOldClass("matrix")
setClassUnion("ConstSparseVal", c("CsparseMatrix", "TsparseMatrix"))

setClassUnion("ConstVal", c("ConstSparseVal", "data.frame", "matrix", "numeric", "complex", "dMatrix", "bigq", "bigz"))
setClassUnion("ConstValORExpr", c("ConstVal", "Expression"))
setClassUnion("ConstValORNULL", c("ConstVal", "NULL"))
setClassUnion("ConstValListORExpr", c("ConstVal", "list", "Expression"))
setClassUnion("ListORExpr", c("list", "Expression"))
setClassUnion("NumORgmp", c("numeric", "bigq", "bigz"))
setClassUnion("NumORNULL", c("numeric", "NULL"))
setClassUnion("NumORLogical", c("logical", "numeric"))
setClassUnion("S4ORNULL", c("S4", "NULL"))

# Helper function since syntax is different for LinOp (list) vs. Expression object
#' @rdname size
setMethod("size", "ListORExpr", function(object) {
  if(is.list(object))
    object$size
  else
    size(object)
})

# Helper function so we can flatten both Expression objects and regular matrices into a single column vector.
setMethod("flatten", "numeric", function(object) { matrix(object, ncol = 1) })

# Casts the second argument of a binary operator as an Expression
.cast_other <- function(binary_op) {
  cast_op <- function(object, other) {
    other <- as.Constant(other)
    binary_op(object, other)
  }
  cast_op
}

# .value_impl.Expression <- function(object) { object@value }
setMethod("value_impl", "Expression", function(object) { object@value })

#' @param x,object An \linkS4class{Expression} object.
#' @describeIn Expression The value of the expression.
setMethod("value", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression The (sub/super)-gradient of the expression with respect to each variable.
setMethod("grad", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression A list of constraints describing the closure of the region where the expression is finite.
setMethod("domain", "Expression", function(object) { stop("Unimplemented") })

setMethod("show", "Expression", function(object) {
  cat("Expression(", curvature(object), ", ", sign(object), ", ", paste(dim(object), collapse = ", "), ")", sep = "")
})

#' @describeIn Expression The string representation of the expression.
#' @export
setMethod("as.character", "Expression", function(x) {
  paste("Expression(", curvature(x), ", ", sign(x), ", ", paste(dim(x), collapse = ", "), ")", sep = "")
})

#' @describeIn Expression The name of the expression.
#' @export
setMethod("name", "Expression", function(x) { stop("Unimplemented") })

#' @describeIn Expression The expression itself.
setMethod("expr", "Expression", function(object) { object })

#'
#' Curvature of Expression
#'
#' The curvature of an expression.
#'
#' @param object An \linkS4class{Expression} object.
#' @return A string indicating the curvature of the expression, either "CONSTANT", "AFFINE", "CONVEX", "CONCAVE", or "UNKNOWN".
#' @docType methods
#' @rdname curvature
#' @export
setMethod("curvature", "Expression", function(object) {
  if(is_constant(object))
    curvature_str <- CONSTANT
  else if(is_affine(object))
    curvature_str <- AFFINE
  else if(is_convex(object))
    curvature_str <- CONVEX
  else if(is_concave(object))
    curvature_str <- CONCAVE
  else
    curvature_str <- UNKNOWN
  curvature_str
})

#'
#' Log-Log Curvature of Expression
#'
#' The log-log curvature of an expression.
#'
#' @param object An \linkS4class{Expression} object.
#' @return A string indicating the log-log curvature of the expression, either "LOG_LOG_CONSTANT", "LOG_LOG_AFFINE", "LOG_LOG_CONVEX", "LOG_LOG_CONCAVE", or "UNKNOWN".
#' @docType methods
#' @rdname log_log_curvature
#' @export
setMethod("log_log_curvature", "Expression", function(object) {
  if(is_log_log_constant(object))
    curvature_str <- LOG_LOG_CONSTANT
  else if(is_log_log_affine(object))
    curvature_str <- LOG_LOG_AFFINE
  else if(is_log_log_convex(object))
    curvature_str <- LOG_LOG_CONVEX
  else if(is_log_log_concave(object))
    curvature_str <- LOG_LOG_CONCAVE
  else
    curvature_str <- UNKNOWN
  curvature_str
})

#' @describeIn Expression The expression is constant if it contains no variables or is identically zero.
setMethod("is_constant", "Expression", function(object) { length(variables(object)) == 0 || 0 %in% dim(object) })

#' @describeIn Expression The expression is affine if it is constant or both convex and concave.
setMethod("is_affine", "Expression", function(object) { is_constant(object) || (is_convex(object) && is_concave(object)) })

#' @describeIn Expression A logical value indicating whether the expression is convex.
setMethod("is_convex", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression A logical value indicating whether the expression is concave.
setMethod("is_concave", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression The expression is DCP if it is convex or concave.
setMethod("is_dcp", "Expression", function(object) { is_convex(object) || is_concave(object) })

#' @describeIn Expression Is the expression log-log constant, i.e., elementwise positive?
setMethod("is_log_log_constant", "Expression", function(object) {
  if(!is_constant(object))
    return(FALSE)

  if(is(object, "Constant") || is(object, "Parameter"))
    return(is_pos(object))
  else
    return(!is.na(value(object)) && all(value(object) > 0))
})

#' @describeIn Expression Is the expression log-log affine?
setMethod("is_log_log_affine", "Expression", function(object) {
  is_log_log_constant(object) || (is_log_log_convex(object) && is_log_log_concave(object))
})

#' @describeIn Expression Is the expression log-log convex?
setMethod("is_log_log_convex", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression Is the expression log-log concave?
setMethod("is_log_log_concave", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression The expression is DGP if it is log-log DCP.
setMethod("is_dgp", "Expression", function(object) { is_log_log_convex(object) || is_log_log_concave(object) })

#' @describeIn Expression A logical value indicating whether the expression is a Hermitian matrix.
setMethod("is_hermitian", "Expression", function(object) { is_real(object) && is_symmetric(object) })

#' @describeIn Expression A logical value indicating whether the expression is a positive semidefinite matrix.
setMethod("is_psd", "Expression", function(object) { FALSE })

#' @describeIn Expression A logical value indicating whether the expression is a negative semidefinite matrix.
setMethod("is_nsd", "Expression", function(object) { FALSE })

#' @describeIn Expression A logical value indicating whether the expression is quadratic.
setMethod("is_quadratic", "Expression", function(object) { is_constant(object) })

#' @describeIn Expression A logical value indicating whether the expression is symmetric.
setMethod("is_symmetric", "Expression", function(object) { is_scalar(object) })

#' @describeIn Expression A logical value indicating whether the expression is piecewise linear.
setMethod("is_pwl", "Expression", function(object) { is_constant(object) })

#' @describeIn Expression A logical value indicating whether the expression is quadratic of piecewise affine.
setMethod("is_qpwa", "Expression", function(object) { is_quadratic(object) || is_pwl(object) })

#'
#' Sign of Expression
#'
#' The sign of an expression.
#'
#' @param x An \linkS4class{Expression} object.
#' @return A string indicating the sign of the expression, either "ZERO", "NONNEGATIVE", "NONPOSITIVE", or "UNKNOWN".
#' @docType methods
#' @rdname sign
#' @export
setMethod("sign", "Expression", function(x) {
  if(!is.na(is_zero(x)) && is_zero(x))
    sign_str <- ZERO
  else if(!is.na(is_nonneg(x)) && is_nonneg(x))
    sign_str <- NONNEG
  else if(!is.na(is_nonpos(x)) && is_nonpos(x))
    sign_str <- NONPOS
  else
    sign_str <- UNKNOWN
  sign_str
})

#' @describeIn Expression The expression is zero if it is both nonnegative and nonpositive.
setMethod("is_zero", "Expression", function(object) { is_nonneg(object) && is_nonpos(object) })

#' @describeIn Expression A logical value indicating whether the expression is nonnegative.
setMethod("is_nonneg", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression A logical value indicating whether the expression is nonpositive.
setMethod("is_nonpos", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression The \code{c(row, col)} dimensions of the expression.
setMethod("dim", "Expression", function(x) { stop("Unimplemented") })

#' @describeIn Expression A logical value indicating whether the expression is real.
setMethod("is_real", "Expression", function(object) { !is_complex(object) })

#' @describeIn Expression A logical value indicating whether the expression is imaginary.
setMethod("is_imag", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression A logical value indicating whether the expression is complex.
setMethod("is_complex", "Expression", function(object) { stop("Unimplemented") })

#' @describeIn Expression The number of entries in the expression.
setMethod("size", "Expression", function(object) { as.integer(prod(dim(object))) })

#' @describeIn Expression The number of dimensions of the expression.
setMethod("ndim", "Expression", function(object) { length(dim(object)) })

#' @describeIn Expression Vectorizes the expression.
setMethod("flatten", "Expression", function(object) { Vec(object) })

#' @describeIn Expression A logical value indicating whether the expression is a scalar.
setMethod("is_scalar", "Expression", function(object) { all(dim(object) == 1) })

#' @describeIn Expression A logical value indicating whether the expression is a row or column vector.
setMethod("is_vector", "Expression", function(object) { ndim(object) <= 1 || (ndim(object) == 2 && min(dim(object)) == 1) })

#' @describeIn Expression A logical value indicating whether the expression is a matrix.
setMethod("is_matrix", "Expression", function(object) { ndim(object) == 2 && nrow(object) > 1 && ncol(object) > 1 })

#' @describeIn Expression Number of rows in the expression.
#' @export
setMethod("nrow", "Expression", function(x) { dim(x)[1] })

#' @describeIn Expression Number of columns in the expression.
#' @export
setMethod("ncol", "Expression", function(x) { dim(x)[2] })

# Slice operators
#' @param x A \linkS4class{Expression} object.
#' @param i,j The row and column indices of the slice.
#' @param ... (Unimplemented) Optional arguments.
#' @param drop (Unimplemented) A logical value indicating whether the result should be coerced to the lowest possible dimension.
#' @rdname Index-class
#' @export
setMethod("[", signature(x = "Expression", i = "missing", j = "missing", drop = "ANY"), function(x, i, j, ..., drop) { x })

#' @rdname Index-class
#' @export
setMethod("[", signature(x = "Expression", i = "numeric", j = "missing", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  if(is_vector(x) && nrow(x) < ncol(x))
    Index(x, Key(NULL, i))   # If only first index given, apply it along longer dimension of vector
  else
    Index(x, Key(i, NULL))
})

#' @rdname Index-class
#' @export
setMethod("[", signature(x = "Expression", i = "missing", j = "numeric", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  Index(x, Key(NULL, j))
})

#' @rdname Index-class
#' @export
setMethod("[", signature(x = "Expression", i = "numeric", j = "numeric", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  Index(x, Key(i, j))
})

#' @param i,j The row and column indices of the slice.
#' @param ... (Unimplemented) Optional arguments.
#' @param drop (Unimplemented) A logical value indicating whether the result should be coerced to the lowest possible dimension.
#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "index", j = "missing", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  if(is_vector(x) && nrow(x) < ncol(x))
    SpecialIndex(x, Key(NULL, i))   # If only first index given, apply it along longer dimension of vector
  else
    SpecialIndex(x, Key(i, NULL))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "missing", j = "index", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  SpecialIndex(x, Key(NULL, j))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "index", j = "index", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  SpecialIndex(x, Key(i, j))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "matrix", j = "index", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  SpecialIndex(x, Key(i, j))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "index", j = "matrix", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  SpecialIndex(x, Key(i, j))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "matrix", j = "matrix", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  SpecialIndex(x, Key(i, j))
})

#' @rdname SpecialIndex-class
#' @export
setMethod("[", signature(x = "Expression", i = "matrix", j = "missing", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
  # This follows conventions in Matrix package, but differs from base handling of matrices
  SpecialIndex(x, Key(i, NULL))
})

#  @rdname Index-class
# setMethod("[", signature(x = "Expression", i = "ANY", j = "ANY", drop = "ANY"), function(x, i, j, ..., drop = TRUE) {
#  stop("Invalid or unimplemented Expression slice operation")
# })

# Arithmetic operators
#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to add.
#' @rdname AddExpression-class
setMethod("+", signature(e1 = "Expression", e2 = "missing"), function(e1, e2) { e1 })

#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to subtract.
#' @rdname NegExpression-class
setMethod("-", signature(e1 = "Expression", e2 = "missing"), function(e1, e2) { NegExpression(expr = e1) })

#' @rdname AddExpression-class
setMethod("+", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { AddExpression(arg_groups = list(e1, e2)) })

#' @rdname AddExpression-class
setMethod("+", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { AddExpression(arg_groups = list(e1, e2)) })

#' @rdname AddExpression-class
setMethod("+", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { e2 + e1 })

#' @rdname NegExpression-class
setMethod("-", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { e1 + NegExpression(expr = e2) })

#' @rdname NegExpression-class
setMethod("-", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { e1 + (-e2) })

#' @rdname NegExpression-class
setMethod("-", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { e1 + NegExpression(expr = e2) })

#'
#' Elementwise multiplication operator
#'
#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to multiply elementwise.
#' @docType methods
#' @rdname mul_elemwise
setMethod("*", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) {
  e1_dim <- dim(e1)
  e2_dim <- dim(e2)

  # if(is.null(e1_dim) || is.null(e2_dim) || is_scalar(e1) || is_scalar(e2))
  if(is.null(e1_dim) || is.null(e2_dim) || (e1_dim[length(e1_dim)] != e2_dim[1] || e1_dim[1] != e2_dim[length(e2_dim)]
                                            && (is_scalar(e1) || is_scalar(e2))) || all(e1_dim == e2_dim))
    Multiply(lh_exp = e1, rh_exp = e2)
  else
    stop("Incompatible dimensions for elementwise multiplication, use '%*%' for matrix multiplication")
})

#' @docType methods
#' @rdname mul_elemwise
setMethod("*", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { as.Constant(e2) * e1 })

#' @docType methods
#' @rdname mul_elemwise
setMethod("*", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { as.Constant(e1) * e2 })

#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to divide. The denominator, \code{e2}, must be a scalar constant.
#' @rdname DivExpression-class
setMethod("/", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) {
  if((is_scalar(e1) || is_scalar(e2)) || all(dim(e1) == dim(e2)))
    DivExpression(lh_exp = e1, rh_exp = e2)
  else
    stop("Incompatible dimensions for division")
})

#' @rdname DivExpression-class
setMethod("/", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { e1 / as.Constant(e2) })

#' @rdname DivExpression-class
setMethod("/", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { as.Constant(e1) / e2 })

#' @param e1 An \linkS4class{Expression} object to exponentiate.
#' @param e2 The power of the exponential. Must be a numeric scalar.
#' @docType methods
#' @rdname power
setMethod("^", signature(e1 = "Expression", e2 = "numeric"), function(e1, e2) { Power(x = e1, p = e2) })

# Matrix operators
#' Matrix Transpose
#'
#' The transpose of a matrix.
#'
#' @param x An \linkS4class{Expression} representing a matrix.
#' @return An \linkS4class{Expression} representing the transposed matrix.
#' @docType methods
#' @aliases t
#' @rdname transpose
#' @method t Expression
#' @export
t.Expression <- function(x) { if(ndim(x) <= 1) x else Transpose(x) }   # Need S3 method dispatch as well

#' @docType methods
#' @rdname transpose
#' @examples
#' x <- Variable(3, 4)
#' t(x)
#' @export
setMethod("t", signature(x = "Expression"), function(x) { if(ndim(x) <= 1) x else Transpose(x) })

#' @param x,y The \linkS4class{Expression} objects or numeric constants to multiply.
#' @rdname MulExpression-class
setMethod("%*%", signature(x = "Expression", y = "Expression"), function(x, y) {
  x_dim <- dim(x)
  y_dim <- dim(y)

  # if(is.null(x_dim) || is.null(y_dim))
  #  stop("Scalar operands are not allowed,  use '*' instead")
  # else if(x_dim[length(x_dim)] != y_dim[1] && (is_scalar(x) || is_scalar(y)))
  #   stop("Matrix multiplication is not allowed, use '*' for elementwise multiplication")
  if(is.null(x_dim) || is.null(y_dim) || is_scalar(x) || is_scalar(y))
    # stop("Scalar operands are not allowed, use '*' instead")
    Multiply(lh_exp = x, rh_exp = y)
  else if(is_constant(x) || is_constant(y))
    MulExpression(lh_exp = x, rh_exp = y)
  else {
    warning("Forming a non-convex expression")
    MulExpression(lh_exp = x, rh_exp = y)
  }
})

#' @rdname MulExpression-class
setMethod("%*%", signature(x = "Expression", y = "ConstVal"), function(x, y) { x %*% as.Constant(y) })

#' @rdname MulExpression-class
setMethod("%*%", signature(x = "ConstVal", y = "Expression"), function(x, y) { as.Constant(x) %*% y })

# Comparison operators
#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to compare.
#' @rdname EqConstraint-class
setMethod("==", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { EqConstraint(e1, e2) })

#' @rdname EqConstraint-class
setMethod("==", signature(e1 = "Expression", e2 = "ConstVal"),   function(e1, e2) { e1 == as.Constant(e2) })

#' @rdname EqConstraint-class
setMethod("==", signature(e1 = "ConstVal",   e2 = "Expression"), function(e1, e2) { as.Constant(e1) == e2 })

#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to compare.
#' @rdname IneqConstraint-class
setMethod("<=", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { IneqConstraint(e1, e2) })

#' @rdname IneqConstraint-class
setMethod("<=", signature(e1 = "Expression", e2 = "ConstVal"),   function(e1, e2) { e1 <= as.Constant(e2) })

#' @rdname IneqConstraint-class
setMethod("<=", signature(e1 = "ConstVal",   e2 = "Expression"), function(e1, e2) { as.Constant(e1) <= e2 })

#' @rdname IneqConstraint-class
setMethod("<",  signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { stop("Unimplemented: Strict inequalities are not allowed.") })

#' @rdname IneqConstraint-class
setMethod("<",  signature(e1 = "Expression", e2 = "ConstVal"),   function(e1, e2) { e1 < as.Constant(e2) })

#' @rdname IneqConstraint-class
setMethod("<",  signature(e1 = "ConstVal",   e2 = "Expression"), function(e1, e2) { as.Constant(e1) < e2 })

#' @rdname IneqConstraint-class
setMethod(">=", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { e2 <= e1 })

#' @rdname IneqConstraint-class
setMethod(">=", signature(e1 = "Expression", e2 = "ConstVal"),   function(e1, e2) { e1 >= as.Constant(e2) })

#' @rdname IneqConstraint-class
setMethod(">=", signature(e1 = "ConstVal",   e2 = "Expression"), function(e1, e2) { as.Constant(e1) >= e2 })

#' @rdname IneqConstraint-class
setMethod(">",  signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { stop("Unimplemented: Strict inequalities are not allowed.") })

#' @rdname IneqConstraint-class
setMethod(">",  signature(e1 = "Expression", e2 = "ConstVal"),   function(e1, e2) { e1 > as.Constant(e2) })

#' @rdname IneqConstraint-class
setMethod(">",  signature(e1 = "ConstVal",   e2 = "Expression"), function(e1, e2) { as.Constant(e1) > e2 })

# Positive definite inequalities
#' @param e1,e2 The \linkS4class{Expression} objects or numeric constants to compare.
#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%>>%", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { PSDConstraint(e1 - e2) })

#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%>>%", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { e1 %>>% as.Constant(e2) })

#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%>>%", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { as.Constant(e1) %>>% e2 })

#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%<<%", signature(e1 = "Expression", e2 = "Expression"), function(e1, e2) { PSDConstraint(e2 - e1) })

#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%<<%", signature(e1 = "Expression", e2 = "ConstVal"), function(e1, e2) { e1 %<<% as.Constant(e2) })

#' @docType methods
#' @rdname PSDConstraint-class
#' @export
setMethod("%<<%", signature(e1 = "ConstVal", e2 = "Expression"), function(e1, e2) { as.Constant(e1) %<<% e2 })

#'
#' The Leaf class.
#'
#' This class represents a leaf node, i.e. a Variable, Constant, or Parameter.
#'
#' @slot id (Internal) A unique integer identification number used internally.
#' @slot dim The dimensions of the leaf.
#' @slot value The numeric value of the leaf.
#' @slot nonneg Is the leaf nonnegative?
#' @slot nonpos Is the leaf nonpositive?
#' @slot complex Is the leaf a complex number?
#' @slot imag Is the leaf imaginary?
#' @slot symmetric Is the leaf a symmetric matrix?
#' @slot diag Is the leaf a diagonal matrix?
#' @slot PSD Is the leaf positive semidefinite?
#' @slot NSD Is the leaf negative semidefinite?
#' @slot hermitian Is the leaf hermitian?
#' @slot boolean Is the leaf boolean? Is the variable boolean? May be \code{TRUE} = entire leaf is boolean, \code{FALSE} = entire leaf is not boolean, or a vector of
#' indices which should be constrained as boolean, where each index is a vector of length exactly equal to the length of \code{dim}.
#' @slot integer Is the leaf integer? The semantics are the same as the \code{boolean} argument.
#' @slot sparsity A matrix representing the fixed sparsity pattern of the leaf.
#' @slot pos Is the leaf strictly positive?
#' @slot neg Is the leaf strictly negative?
#' @name Leaf-class
#' @aliases Leaf
#' @rdname Leaf-class
Leaf <- setClass("Leaf", representation(dim = "NumORNULL", value = "ConstVal", nonneg = "logical", nonpos = "logical",
                                        complex = "logical", imag = "logical", symmetric = "logical", diag = "logical",
                                        PSD = "logical", NSD = "logical", hermitian = "logical", boolean = "NumORLogical", integer = "NumORLogical",
                                        sparsity = "matrix", pos = "logical", neg = "logical",
                                        attributes = "list", boolean_idx = "matrix", integer_idx = "matrix"),
                         prototype(value = NA_real_, nonneg = FALSE, nonpos = FALSE,
                                   complex = FALSE, imag = FALSE, symmetric = FALSE, diag = FALSE,
                                   PSD = FALSE, NSD = FALSE, hermitian = FALSE, boolean = FALSE, integer = FALSE,
                                   sparsity = matrix(0, nrow = 0, ncol = 1), pos = FALSE, neg = FALSE,
                                   attributes = list(), boolean_idx = matrix(0, nrow = 0, ncol = 1), integer_idx = matrix(0, nrow = 0, ncol = 1)), contains = "Expression")

setMethod("initialize", "Leaf", function(.Object, ..., dim, value = NA_real_, nonneg = FALSE, nonpos = FALSE, complex = FALSE, imag = FALSE, symmetric = FALSE, diag = FALSE, PSD = FALSE, NSD = FALSE, hermitian = FALSE, boolean = FALSE, integer = FALSE, sparsity = matrix(0, nrow = 0, ncol = 1), pos = FALSE, neg = FALSE, attributes = list(), boolean_idx = matrix(0, nrow = 0, ncol = 1), integer_idx = matrix(0, nrow = 0, ncol = 1)) {
  if(length(dim) > 2)
    stop("Expressions of dimension greater than 2 are not supported.")

  for(d in dim) {
    if(!intf_is_integer(d) || d <= 0)
      stop("Invalid dimensions ", dim)
  }
  .Object@dim <- as.integer(dim)

  if((PSD || NSD || symmetric || diag || hermitian) && (length(dim) != 2 || dim[1] != dim[2]))
    stop("Invalid dimensions ", dim, ". Must be a square matrix.")

  # Construct matrix of boolean/integer-constrained indices.
  if(is.logical(boolean)) {
    if(boolean)
      .Object@boolean_idx <- as.matrix(do.call(expand.grid, lapply(dim, function(k) { 1:k })))
    else
      .Object@boolean_idx <- matrix(0, nrow = 0, ncol = length(dim))
    bool_attr <- boolean
  } else {
    .Object@boolean_idx <- boolean
    bool_attr <- (nrow(boolean) > 0)
  }

  if(is.logical(integer)) {
    if(integer)
      .Object@integer_idx <- as.matrix(do.call(expand.grid, lapply(dim, function(k) { 1:k })))
    else
      .Object@integer_idx <- matrix(0, nrow = 0, ncol = length(dim))
    int_attr <- integer
  } else {
    .Object@integer_idx <- integer
    int_attr <- (nrow(integer) > 0)
  }

  # Process attributes.
  .Object@attributes <- list(nonneg = nonneg, nonpos = nonpos, pos = pos, neg = neg, complex = complex, imag = imag,
                             symmetric = symmetric, diag = diag, PSD = PSD, NSD = NSD, hermitian = hermitian,
                             boolean = bool_attr, integer = int_attr, sparsity = sparsity)

  # Only one attribute can be TRUE (except boolean and integer).
  attrs <- .Object@attributes
  attrs$sparsity <- prod(dim(attrs$sparsity)) != 0
  true_attr <- sum(unlist(attrs))

  if(bool_attr && int_attr)
    true_attr <- true_attr - 1
  if(true_attr > 1)
    stop("Cannot set more than one special attribute.")

  if(!any(is.na(value)))
    value(.Object) <- value
  callNextMethod(.Object, ...)
})

setMethod("get_attr_str", "Leaf", function(object) {
  # Get a string representing the attributes
  attr_str <- ""
  for(attr in names(object@attributes)) {
    val <- object@attributes[[attr]]
    if(attr != "real" && !is.null(val)) {
      if(nchar(attr_str) == 0)
        attr_str <- sprintf("%s=%s", attr, val)
      else
        attr_str <- paste(attr_str, sprintf("%s=%s", attr, val), sep = ", ")
    }
  }
  attr_str
})

# TODO: Get rid of this and just skip calling copy on Leaf objects.
setMethod("copy", "Leaf", function(object, args = NULL, id_objects = list()) {
  # if("id" %in% names(attributes(object)) && as.character(object@id) %in% names(id_objects))
  if(!is.na(object@id) && as.character(object@id) %in% names(id_objects))
    return(id_objects[[as.character(object@id)]])
  return(object)   # Leaves are not deep copied.
})

#' @param object,x A \linkS4class{Leaf} object.
#' @describeIn Leaf Leaves are not copied.
setMethod("get_data", "Leaf", function(object) { list() })

#' @describeIn Leaf The dimensions of the leaf node.
setMethod("dim", "Leaf", function(x) { x@dim })

#' @describeIn Leaf List of \linkS4class{Variable} objects in the leaf node.
setMethod("variables", "Leaf", function(object) { list() })

#' @describeIn Leaf List of \linkS4class{Parameter} objects in the leaf node.
setMethod("parameters", "Leaf", function(object) { list() })

#' @describeIn Leaf List of \linkS4class{Constant} objects in the leaf node.
setMethod("constants", "Leaf", function(object) { list() })

#' @describeIn Leaf List of \linkS4class{Atom} objects in the leaf node.
setMethod("atoms", "Leaf", function(object) { list() })

#' @describeIn Leaf A logical value indicating whether the leaf node is convex.
setMethod("is_convex", "Leaf", function(object) { TRUE })

#' @describeIn Leaf A logical value indicating whether the leaf node is concave.
setMethod("is_concave", "Leaf", function(object) { TRUE })

#' @describeIn Leaf Is the expression log-log convex?
setMethod("is_log_log_convex", "Leaf", function(object) { is_pos(object) })

#' @describeIn Leaf Is the expression log-log concave?
setMethod("is_log_log_concave", "Leaf", function(object) { is_pos(object) })

#' @describeIn Leaf A logical value indicating whether the leaf node is nonnegative.
setMethod("is_nonneg", "Leaf", function(object) { object@attributes$nonneg || object@attributes$pos || object@attributes$boolean })

#' @describeIn Leaf A logical value indicating whether the leaf node is nonpositive.
setMethod("is_nonpos", "Leaf", function(object) { object@attributes$nonpos || object@attributes$neg })

#' @describeIn Leaf Is the expression positive?
setMethod("is_pos", "Leaf", function(object) { object@attributes$pos })

#' @describeIn Leaf Is the expression negative?
setMethod("is_neg", "Leaf", function(object) { object@attributes$neg })

#' @describeIn Leaf A logical value indicating whether the leaf node is hermitian.
setMethod("is_hermitian", "Leaf", function(object) {
  (is_real(object) && is_symmetric(object)) || object@attributes$hermitian || is_psd(object) || is_nsd(object)
})

#' @describeIn Leaf A logical value indicating whether the leaf node is symmetric.
setMethod("is_symmetric", "Leaf", function(object) {
  is_scalar(object) || any(sapply(c("diag", "symmetric", "PSD", "NSD"), function(key) { object@attributes[[key]] }))
})

#' @describeIn Leaf A logical value indicating whether the leaf node is imaginary.
setMethod("is_imag", "Leaf", function(object) { object@attributes$imag })

#' @describeIn Leaf A logical value indicating whether the leaf node is complex.
setMethod("is_complex", "Leaf", function(object) {
  object@attributes$complex || is_imag(object) || object@attributes$hermitian
})

#' @describeIn Leaf A list of constraints describing the closure of the region where the leaf node is finite. Default is the full domain.
setMethod("domain", "Leaf", function(object) {
  domain <- list()
  if(object@attributes$nonneg)
    domain <- c(domain, object >= 0)
  else if(object@attributes$nonpos)
    domain <- c(domain, object <= 0)
  else if(object@attributes$PSD)
    domain <- c(domain, object %>>% 0)
  else if(object@attributes$NSD)
    domain <- c(domain, object %<<% 0)
  return(domain)
})

#' @param value A numeric scalar, vector, or matrix.
#' @describeIn Leaf Project value onto the attribute set of the leaf.
setMethod("project", "Leaf", function(object, value) {
  if(!is_complex(object))
    value <- Re(value)

  if(object@attributes$nonpos && object@attributes$nonneg)
    return(0*value)
  else if(object@attributes$nonpos || object@attributes$neg)
    return(pmin(value, 0))
  else if(object@attributes$nonneg || object@attributes$pos)
    return(pmax(value, 0))
  else if(object@attributes$imag)
    return(Im(value)*1i)
  else if(object@attributes$complex)
    return(as.complex(value))
  else if(object@attributes$boolean)
    # TODO: Respect the boolean indices.
    return(round(pmax(pmin(value, 1), 0)))
  else if(object@attributes$integer)
    # TODO: Respect the integer indices. Also, variable may be integer in some indices and boolean in others.
    return(round(value))
  else if(object@attributes$diag) {
    val <- diag(value)
    return(sparseMatrix(i = 1:length(val), j = 1:length(val), x = val))
  } else if(object@attributes$hermitian)
    return((value + t(Conj(value)))/2)
  else if(any(sapply(c("symmetric", "PSD", "NSD"), function(key) { object@attributes[[key]] }))) {
    value <- value + t(value)
    value <- value/2
    if(object@attributes$symmetric)
      return(value)

    wV <- eigen(value, symmetric = TRUE, only.values = FALSE)
    w <- wV$values
    V <- wV$vectors

    if(object@attributes$PSD) {
      bad <- w < 0
      if(!any(bad))
        return(value)
      w[bad] <- 0
    } else {   # NSD
      bad <- w > 0
      if(!any(bad))
        return(value)
      w[bad] <- 0
    }
    return((V %*% diag(w)) %*% t(V))
  } else
    return(value)
})

#' @describeIn Leaf Project and assign a value to the leaf.
setMethod("project_and_assign", "Leaf", function(object, value) {
  object@value <- project(object, value)
  return(object)
})

#' @describeIn Leaf Get the value of the leaf.
setMethod("value", "Leaf", function(object) { object@value })

#' @describeIn Leaf Set the value of the leaf.
setReplaceMethod("value", "Leaf", function(object, value) {
  object@value <- validate_val(object, value)
  return(object)
})

#' @param val The assigned value.
#' @describeIn Leaf Check that \code{val} satisfies symbolic attributes of leaf.
setMethod("validate_val", "Leaf", function(object, val) {
  if(!any(is.na(val))) {
    val <- intf_convert(val)
    if(any(intf_dim(val) != dim(object)))
      stop("Invalid dimensions (", paste(intf_dim(val), collapse = ","), ") for value")
    projection <- project(object, val)
    delta <- abs(val - projection)

    if(is(delta, "sparseMatrix"))
      close_enough <- all(abs(delta@x) <= SPARSE_PROJECTION_TOL)
    else {
      delta <- as.matrix(delta)
      if(object@attributes$PSD || object@attributes$NSD)
        close_enough <- norm(delta, type = "2") <= PSD_NSD_PROJECTION_TOL
      else
        close_enough <- all(abs(delta) <= GENERAL_PROJECTION_TOL)
    }

    if(!close_enough) {
      if(object@attributes$nonneg)
        attr_str <- "nonnegative"
      else if(object@attributes$pos)
        attr_str <- "positive"
      else if(object@attributes$nonpos)
        attr_str <- "nonpositive"
      else if(object@attributes$neg)
        attr_str <- "negative"
      else if(object@attributes$diag)
        attr_str <- "diagonal"
      else if(object@attributes$PSD)
        attr_str <- "positive semidefinite"
      else if(object@attributes$NSD)
        attr_str <- "negative semidefinite"
      else if(object@attributes$imag)
        attr_str <- "imaginary"
      else {
        attr_str <- names(object@attributes)[unlist(object@attributes) == 1]
        attr_str <- c(attr_str, "real")[1]
      }
      stop("Value must be ", attr_str)
    }
  }
  return(val)
})

#' @describeIn Leaf A logical value indicating whether the leaf node is a positive semidefinite matrix.
setMethod("is_psd", "Leaf", function(object) { object@attributes$PSD })

#' @describeIn Leaf A logical value indicating whether the leaf node is a negative semidefinite matrix.
setMethod("is_nsd", "Leaf", function(object) { object@attributes$NSD })

#' @describeIn Leaf Leaf nodes are always quadratic.
setMethod("is_quadratic", "Leaf", function(object) { TRUE })

#' @describeIn Leaf Leaf nodes are always piecewise linear.
setMethod("is_pwl", "Leaf", function(object) { TRUE })
