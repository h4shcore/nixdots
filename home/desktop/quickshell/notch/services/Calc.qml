pragma Singleton
import QtQuick
import Quickshell

// Tiny safe calculator for the launcher ("=" mode, or auto when the query looks like math).
// Recursive-descent parser, no eval. Supports + - * / % ^ ( ), constants pi/e/tau,
// functions sqrt cbrt abs sin cos tan asin acos atan ln log log2 exp floor ceil round, pow/min/max(a, b).
Singleton {
    id: root

    readonly property var consts: ({ pi: Math.PI, e: Math.E, tau: Math.PI * 2 })
    readonly property var fn1: ({
        sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, sin: Math.sin, cos: Math.cos, tan: Math.tan,
        asin: Math.asin, acos: Math.acos, atan: Math.atan, ln: Math.log, log: Math.log10, log2: Math.log2,
        exp: Math.exp, floor: Math.floor, ceil: Math.ceil, round: Math.round
    })
    readonly property var fn2: ({ pow: Math.pow, min: Math.min, max: Math.max })

    function tokenize(src) {
        const s = src.toLowerCase().replace(/×/g, "*").replace(/÷/g, "/").replace(/\*\*/g, "^");
        const re = /^\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([a-z_][a-z0-9_]*)|([-+*\/%^(),]))/;
        const out = [];
        let rest = s;
        while (rest.trim() !== "") {
            const m = re.exec(rest);
            if (!m) return null;
            rest = rest.slice(m[0].length);
            if (m[1] !== undefined) out.push({ t: "n", v: parseFloat(m[1]) });
            else if (m[2] !== undefined) out.push({ t: "i", v: m[2] });
            else out.push({ t: "o", v: m[3] });
        }
        return out;
    }

    // returns { value, complex } or null
    function evaluate(src) {
        const tok = tokenize(src);
        if (!tok || tok.length === 0) return null;
        let i = 0;
        let complex = false;   // has an operator or function (not just a bare number/constant)
        let hasNum = false;

        const peek = () => tok[i];
        const isOp = v => tok[i] && tok[i].t === "o" && tok[i].v === v;

        function expr() {
            let l = term();
            while (isOp("+") || isOp("-")) {
                const op = tok[i++].v;
                complex = true;
                const r = term();
                l = op === "+" ? l + r : l - r;
            }
            return l;
        }
        function term() {
            let l = unary();
            for (;;) {
                if (isOp("*") || isOp("/") || isOp("%")) {
                    const op = tok[i++].v;
                    complex = true;
                    const r = unary();
                    l = op === "*" ? l * r : op === "/" ? l / r : l % r;
                } else if (isOp("(") || (peek() && peek().t === "i")) {
                    // implicit multiplication: 2(3+4), 2pi
                    complex = true;
                    l = l * unary();
                } else break;
            }
            return l;
        }
        function unary() {
            if (isOp("-")) { i++; complex = true; return -unary(); }
            if (isOp("+")) { i++; return unary(); }
            return power();
        }
        function power() {
            const b = atom();
            if (isOp("^")) { i++; complex = true; return Math.pow(b, unary()); }
            return b;
        }
        function atom() {
            const t = tok[i];
            if (!t) throw "end";
            if (t.t === "n") { i++; hasNum = true; return t.v; }
            if (t.t === "o" && t.v === "(") {
                i++;
                const v = expr();
                if (!isOp(")")) throw "paren";
                i++;
                return v;
            }
            if (t.t === "i") {
                i++;
                if (root.consts[t.v] !== undefined && !isOp("(")) { hasNum = true; return root.consts[t.v]; }
                const f1 = root.fn1[t.v];
                const f2 = root.fn2[t.v];
                if (!f1 && !f2) throw "unknown";
                if (!isOp("(")) throw "call";
                i++;
                const a = expr();
                let b;
                if (isOp(",")) { i++; b = expr(); }
                if (!isOp(")")) throw "paren";
                i++;
                complex = true;
                hasNum = true;
                if (b !== undefined) { if (!f2) throw "arity"; return f2(a, b); }
                if (!f1) throw "arity";
                return f1(a);
            }
            throw "token";
        }

        try {
            const v = expr();
            if (i !== tok.length) return null;
            if (!isFinite(v) || !hasNum) return null;
            return { value: v, complex: complex };
        } catch (err) {
            return null;
        }
    }

    function fmt(v) {
        if (Number.isInteger(v) && Math.abs(v) < 1e15) return String(v);
        const a = Math.abs(v);
        if (a >= 1e15 || (a !== 0 && a < 1e-9)) return v.toExponential(8).replace(/\.?0+e/, "e");
        return String(parseFloat(v.toPrecision(12)));
    }

    function makeRow(expr, r) {
        const text = fmt(r.value);
        return { id: "calc", kind: "calc", title: text, subtitle: expr.trim(), text: text };
    }

    // "=" mode: any valid expression
    function force(expr) {
        const r = evaluate(expr);
        return r ? makeRow(expr, r) : null;
    }

    // plain query: only when it clearly is math (has an operator/function), so app names never trigger it
    function auto(expr) {
        if (!/^[0-9a-z\s.+\-*\/%^(),×÷]+$/i.test(expr)) return null;
        const r = evaluate(expr);
        return r && r.complex ? makeRow(expr, r) : null;
    }
}
