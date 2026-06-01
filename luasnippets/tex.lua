local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local snips = {
	-- ============================================================
	-- Environments
	-- ============================================================

	s("eq", fmt([[
\begin{{equation}}
	{}
\end{{equation}}
]], { i(1) })),

	s("eq*", fmt([[
\begin{{equation*}}
	{}
\end{{equation*}}
]], { i(1) })),

	s("al", fmt([[
\begin{{align}}
	{}
\end{{align}}
]], { i(1) })),

	s("al*", fmt([[
\begin{{align*}}
	{}
\end{{align*}}
]], { i(1) })),

	s("mk", fmt("${}$", { i(1) })),

	s("dm", fmt([[
\[
	{}
\]
]], { i(1) })),

	s("beg", fmt([[
\begin{{{}}}
	{}
\end{{{}}}
]], { i(1), i(2), rep(1) })),

	s("enum", fmt([[
\begin{{enumerate}}
	\item {}
\end{{enumerate}}
]], { i(1) })),

	s("item", fmt([[
\begin{{itemize}}
	\item {}
\end{{itemize}}
]], { i(1) })),

	-- ============================================================
	-- Theorem-like
	-- ============================================================

	s("thm", fmt([[
\begin{{theorem}}
	{}
\end{{theorem}}
]], { i(1) })),

	s("lem", fmt([[
\begin{{lemma}}
	{}
\end{{lemma}}
]], { i(1) })),

	s("cor", fmt([[
\begin{{corollary}}
	{}
\end{{corollary}}
]], { i(1) })),

	s("defn", fmt([[
\begin{{definition}}
	{}
\end{{definition}}
]], { i(1) })),

	s("prop", fmt([[
\begin{{proposition}}
	{}
\end{{proposition}}
]], { i(1) })),

	s("pf", fmt([[
\begin{{proof}}
	{}
\end{{proof}}
]], { i(1) })),

	s("rem", fmt([[
\begin{{remark}}
	{}
\end{{remark}}
]], { i(1) })),

	-- ============================================================
	-- Figure & Table
	-- ============================================================

	s("fig", fmt([[
\begin{{figure}}[htbp]
	\centering
	\includegraphics[width={}]{{{}}}
	\caption{{{} }}
	\label{{fig:{} }}
\end{{figure}}
]], { i(1, "0.8\\textwidth"), i(2), i(3), i(4) })),

	s("tab", fmt([[
\begin{{table}}[htbp]
	\centering
	\caption{{{} }}
	\label{{tab:{} }}
	\begin{{tabular}}{{{}}}
		\toprule
		{}
		\midrule
		{}
		\bottomrule
	\end{{tabular}}
\end{{table}}
]], { i(1), i(2), i(3, "ccc"), i(4), i(5) })),

	-- ============================================================
	-- Sections
	-- ============================================================

	s("sec", fmt([[
\section{{{} }}
\label{{sec:{} }}
]], { i(1), i(2) })),

	s("sub", fmt([[
\subsection{{{} }}
\label{{subsec:{} }}
]], { i(1), i(2) })),

	s("ssub", fmt([[
\subsubsection{{{} }}
\label{{subsec:{} }}
]], { i(1), i(2) })),

	-- ============================================================
	-- Math shortcuts
	-- ============================================================

	s("lr", fmt("\\left( {} \\right)", { i(1) })),
	s("LR", fmt("\\left[ {} \\right]", { i(1) })),
	s("lR", fmt("\\left\\{{ {} \\right\\}}", { i(1) })),

	s("sum", fmt("\\sum_{{ {} }}^{{ {} }}", { i(1, "i=1"), i(2, "n") })),
	s("int", fmt("\\int_{{ {} }}^{{ {} }}", { i(1), i(2) })),
	s("INT", fmt("\\int_{{ {} }}^{{ {} }} {} \\,d{}", { i(1), i(2), i(3), i(4) })),
	s("lim", fmt("\\lim_{{ {} \\to {} }}", { i(1), i(2) })),
	s("frac", fmt("\\frac{{ {} }}{{ {} }}", { i(1), i(2) })),
	s("ff", fmt("\\frac{{ {} }}{{ {} }}", { i(1), i(2) })),
	s("dff", fmt("\\dfrac{{ {} }}{{ {} }}", { i(1), i(2) })),
	s("sqrt", fmt("\\sqrt{{ {} }}", { i(1) })),
	s("abs", fmt("\\left| {} \\right|", { i(1) })),
	s("norm", fmt("\\left\\| {} \\right\\|", { i(1) })),
	s("set", fmt("\\left\\{{ {} \\right\\}}", { i(1) })),
	s("ceil", fmt("\\left\\lceil {} \\right\\rceil", { i(1) })),
	s("floor", fmt("\\left\\lfloor {} \\right\\rfloor", { i(1) })),
	s("vec", fmt("\\vec{{ {} }}", { i(1) })),
	s("hat", fmt("\\hat{{ {} }}", { i(1) })),
	s("bar", fmt("\\bar{{ {} }}", { i(1) })),
	s("dot", fmt("\\dot{{ {} }}", { i(1) })),
	s("ddot", fmt("\\ddot{{ {} }}", { i(1) })),
	s("ub", fmt("\\underbrace{{ {} }}_{{ {} }}", { i(1), i(2) })),
	s("ob", fmt("\\overbrace{{ {} }}^{{ {} }}", { i(1), i(2) })),

	s("inf", { t("\\infty") }),
	s("pto", { t("\\partial") }),
	s("nab", { t("\\nabla") }),
	s("grad", { t("\\nabla") }),
	s("del", { t("\\partial") }),
	s("cdot", { t("\\cdot") }),
	s("times", { t("\\times") }),
	s("leq", { t("\\leq") }),
	s("geq", { t("\\geq") }),
	s("neq", { t("\\neq") }),
	s("approx", { t("\\approx") }),
	s("->", { t("\\to") }),
	s("|->", { t("\\mapsto") }),
	s("inn", { t("\\in") }),
	s("notin", { t("\\notin") }),
	s("sube", { t("\\subseteq") }),
	s("supe", { t("\\supseteq") }),

	-- text wrappers
	s("bf", fmt("\\textbf{{ {} }}", { i(1) })),
	s("em", fmt("\\emph{{ {} }}", { i(1) })),
	s("tt", fmt("\\texttt{{ {} }}", { i(1) })),
	s("mbb", fmt("\\mathbb{{ {} }}", { i(1) })),
	s("mcal", fmt("\\mathcal{{ {} }}", { i(1) })),
	s("mrm", fmt("\\mathrm{{ {} }}", { i(1) })),

	-- \mathcal shortcuts
	s("cA", { t("\\mathcal{A}") }),
	s("cB", { t("\\mathcal{B}") }),
	s("cC", { t("\\mathcal{C}") }),
	s("cD", { t("\\mathcal{D}") }),
	s("cF", { t("\\mathcal{F}") }),
	s("cG", { t("\\mathcal{G}") }),
	s("cH", { t("\\mathcal{H}") }),
	s("cL", { t("\\mathcal{L}") }),
	s("cM", { t("\\mathcal{M}") }),
	s("cN", { t("\\mathcal{N}") }),
	s("cO", { t("\\mathcal{O}") }),
	s("cP", { t("\\mathcal{P}") }),
	s("cR", { t("\\mathcal{R}") }),
	s("cS", { t("\\mathcal{S}") }),
	s("cT", { t("\\mathcal{T}") }),
	s("cZ", { t("\\mathcal{Z}") }),

	-- \mathbb shortcuts
	s("bbR", { t("\\mathbb{R}") }),
	s("bbN", { t("\\mathbb{N}") }),
	s("bbZ", { t("\\mathbb{Z}") }),
	s("bbQ", { t("\\mathbb{Q}") }),
	s("bbC", { t("\\mathbb{C}") }),
	s("bbF", { t("\\mathbb{F}") }),

	-- Greek: "` + letter"
	s("`a", { t("\\alpha") }),
	s("`b", { t("\\beta") }),
	s("`g", { t("\\gamma") }),
	s("`G", { t("\\Gamma") }),
	s("`d", { t("\\delta") }),
	s("`D", { t("\\Delta") }),
	s("`e", { t("\\epsilon") }),
	s("`E", { t("\\varepsilon") }),
	s("`z", { t("\\zeta") }),
	s("`h", { t("\\eta") }),
	s("`t", { t("\\theta") }),
	s("`T", { t("\\Theta") }),
	s("`k", { t("\\kappa") }),
	s("`l", { t("\\lambda") }),
	s("`L", { t("\\Lambda") }),
	s("`m", { t("\\mu") }),
	s("`n", { t("\\nu") }),
	s("`x", { t("\\xi") }),
	s("`X", { t("\\Xi") }),
	s("`p", { t("\\pi") }),
	s("`P", { t("\\Pi") }),
	s("`r", { t("\\rho") }),
	s("`s", { t("\\sigma") }),
	s("`S", { t("\\Sigma") }),
	s("`u", { t("\\upsilon") }),
	s("`U", { t("\\Upsilon") }),
	s("`f", { t("\\phi") }),
	s("`F", { t("\\Phi") }),
	s("`c", { t("\\chi") }),
	s("`y", { t("\\psi") }),
	s("`Y", { t("\\Psi") }),
	s("`o", { t("\\omega") }),
	s("`O", { t("\\Omega") }),

	-- ============================================================
	-- Matrices
	-- ============================================================

	s("pmat", fmt([[
\begin{{pmatrix}}
	{}
\end{{pmatrix}}
]], { i(1) })),

	s("bmat", fmt([[
\begin{{bmatrix}}
	{}
\end{{bmatrix}}
]], { i(1) })),

	s("Bmat", fmt([[
\begin{{Bmatrix}}
	{}
\end{{Bmatrix}}
]], { i(1) })),

	s("vmat", fmt([[
\begin{{vmatrix}}
	{}
\end{{vmatrix}}
]], { i(1) })),

	s("Vmat", fmt([[
\begin{{Vmatrix}}
	{}
\end{{Vmatrix}}
]], { i(1) })),

	-- ============================================================
	-- Cases
	-- ============================================================

	s("cases", fmt([[
\begin{{cases}}
	{}
\end{{cases}}
]], { i(1) })),

	-- ============================================================
	-- Citations & Refs
	-- ============================================================

	s("cit", fmt("\\cite{{ {} }}", { i(1) })),
	s("ref", fmt("\\ref{{ {} }}", { i(1) })),
	s("eqref", fmt("\\eqref{{ {} }}", { i(1) })),
	s("lab", fmt("\\label{{ {} }}", { i(1) })),
}

return snips
