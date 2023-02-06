const infix_ops = [
    ["==", 6],
    ["!=", 6],
    ["+", 13],
    ["-", 13],
    ["*", 14],
    ["/", 14],
    ["%", 14],
    ["&", 5],
    ["|", 3],
    ["&&", 2],
    ["||", 1],
    ["^", 4],
    ["<", 8],
    [">", 8],
    ["<=", 8],
    [">=", 8],
    ["<<", 12],
    [">>", 12],
    [">>>", 12],
];

module.exports = grammar({
    name: 'virgil',
    word: $ => $.identifier,
    extras: $ => [
        $.comment,
        /\s/
    ],
    conflicts: $ => [
        [$.ident_param]
    ],

    rules: {
        source_file: $ => repeat($.top_level_decl),
        top_level_decl: $ => choice(
            $.class_decl,
            $.component_decl,
            $.variant_decl,
            $.enum_decl,
            $.export_decl,
            $.var_member,
            $.def_member
        ),

        class_decl: $ => seq(
            "class",
            field('name', $.ident_param),
            optional(seq("(", optional(field('parameters', $.var_param_decls)), ")")),
            optional(seq("extends", field('extendsType', $.type_ref), optional(field('extendsTypeParams', $.tuple_expr)))),
            "{", field('members', repeat($.member)), "}"
        ),
        component_decl: $ => seq(
            optional("import"),
            "component", 
            field('name', $.identifier), "{",
            field('members', repeat($.member)), "}"
        ),
        variant_decl: $ => seq(
            "type", field('name', $.ident_param),
            optional(seq("(", optional(field('decls', $.param_decls)), ")")),
            "{", field('members', repeat($.variant_member)), "}"
        ),
        enum_decl: $ => seq(
            "enum", field('name', $.identifier),
            optional(seq("(", optional(field('parameters', $.param_decls)), ")")),
            "{", optional(field('cases', $.enum_cases)), "}"
        ),

        member: $ => choice($.def_member, $.new_member, $.var_member),
        variant_member: $ => choice($.def_method, $.variant_case),
        var_member: $ => seq(
            optional("private"), "var", field('decls', $.var_decls), ";"
        ),
        def_member: $ => seq(
            optional("private"),
            "def",
            choice(
                seq(optional("var"), $.var_decls, ";"),
                $.index_method,
                $.method
            )
        ),
        new_member: $ => seq(
            "new", "(", optional($.new_param_decls), ")",
            optional(seq(optional(":"), "super", $.tuple_expr)),
            $.block_stmt
        ),
        def_method: $ => seq(
            optional("private"),
            "def",
            choice($.index_method, $.method)
        ),
        variant_case: $ => seq(
            "case", field('name', $.identifier),
            optional(seq("(", optional(field('decls', $.param_decls)), ")")),
            choice(";", seq("{", field('method', repeat($.def_method)), "}"))
        ),
        enum_case: $ => seq(
            field('name', $.identifier),
            optional(seq("(", field('parameters', optional(seq($.expr, repeat(seq(",", $.expr))))), ")"))
        ),
        enum_cases: $ => seq(
            $.enum_case, repeat(seq(",", $.enum_case))
        ),

        var_param_decl: $ => seq(
            optional("var"),
            field('name', $.identifier), ":", field('type', $.type_ref)
        ),
        var_param_decls: $ => seq(
            $.var_param_decl,
            repeat(seq(",", $.var_param_decl))
        ),
        param_decl: $ => seq(
            field('name', $.identifier), ":", 
            field('type', $.type_ref)
        ),
        param_decls: $ => seq(
            $.param_decl,
            repeat(seq(",", $.param_decl)),
        ),
        new_param_decl: $ => seq(
            field('name', $.identifier),
            optional(seq(":", field('type', $.type_ref)))
        ),
        new_param_decls: $ => seq(
            $.new_param_decl,
            repeat(seq(",", $.new_param_decl))
        ),
        ident_param: $ => seq(
            field('name', $.identifier),
            optional(seq("<", field('typeArgs', $.type_args), ">"))
        ),
        type_ref: $ => prec.left(1, seq(
            choice(
                seq("(", field('tuple', optional($.type_args)), ")"),
                seq(field('member', seq($.ident_param, repeat(seq(".", $.ident_param)))))
            ),
            field('function', repeat(seq("->", $.type_ref)))
        )),
        type_args: $ => seq($.type_ref, repeat(seq(",", $.type_ref))),

        var_decl: $ => seq(
            field('name', $.identifier),
            field('rest',
                choice(
                    seq(":", $.type_ref),
                    seq("=", $.expr),
                    seq(":", $.type_ref, "=", $.expr)
                )
            )
        ),
        var_decls: $ => seq(
            $.var_decl, repeat(seq(",", $.var_decl))
        ),
        index_method: $ => seq(
            $.ident_param, "[", $.var_param_decls, "]",
            choice(seq("=", $.param_decl), seq("->", $.type_ref)),
            $.method_body
        ),
        method: $ => seq(
            field('name', $.ident_param), "(", optional(field('parameters', $.var_param_decls)), ")",
            optional(seq("->", field('returnType', choice("this", $.type_ref)))),
            field('body', $.method_body)
        ),

        method_body: $ => choice(";", $.block_stmt),
        export_decl: $ => seq("export", choice(
            $.def_method,
            seq(choice($.string, $.identifier), optional(seq("=", $.symbol_param)), ";")
        )),
        symbol: $ => seq($.identifier, repeat(seq(".", $.identifier))),
        symbol_param: $ => seq($.ident_param, repeat(seq(".", $.ident_param))),

        block_stmt: $ => seq("{", repeat($.stmt), "}"),
        stmt: $ => choice(
            $.block_stmt,
            $.empty_stmt,
            $.if_stmt,
            $.while_stmt,
            $.match_stmt,
            $.def_stmt,
            $.var_stmt,
            $.break_stmt,
            $.continue_stmt, 
            $.return_stmt,
            $.for_stmt,
            $.expr_stmt
        ),
        empty_stmt: $ => ";",
        if_stmt: $ => prec.left(1, seq("if", "(", $.expr, ")", $.stmt, optional(seq("else", $.stmt)))),
        while_stmt: $ => seq("while", "(", $.expr, ")", $.stmt),
        match_stmt: $ => prec.left(1, seq(
            "match", "(", $.expr, ")", "{",
            optional(repeat1($.match_case)),
            "}", optional(seq("else", $.stmt))
        )),
        match_case: $ => seq(
            choice("_", seq($.match_pattern, repeat(seq(",", $.match_pattern)))),
            "=>", $.stmt
        ),
        match_pattern: $ => choice($.id_type_pattern, $.symbol_pattern, $.const),
        id_type_pattern: $ => seq($.identifier, ":", $.type_ref),
        symbol_pattern: $ => seq($.symbol, optional(seq("(", optional(seq($.identifier, repeat(seq(",", $.identifier)))), ")"))),
        var_stmt: $ => seq("var", $.var_decls, ";"),
        def_stmt: $ => seq("def", $.var_decls, ";"),
        break_stmt: $ => seq("break", ";"),
        continue_stmt: $ => seq("continue", ";"),
        return_stmt: $ => seq("return", optional($.expr), ";"),
        for_stmt: $ => seq(
            "for", "(",
            choice(
                $.var_decl,
                $.identifier
            ),
            choice(
                seq("<", $.expr),
                seq("in", $.expr),
                seq(";", $.expr, ";", $.expr)
            ),
            ")", $.stmt
        ),
        expr_stmt: $ => seq($.expr, ";"),

        expr: $ => seq($.sub_expr, optional(seq($.assign, $.expr))),
        exprs: $ => seq($.expr, repeat(seq(",", $.expr))),
        sub_expr: $ =>
            choice(
                $.in_expr,
                ...infix_ops.map(([op, op_prec]) => prec.left(op_prec, seq($.sub_expr, op, $.sub_expr)))
            )
        ,
        in_expr: $ => seq($.term, repeat($.term_suffix)),
        term_suffix: $ => choice($.member_suffix, $.apply_suffix, $.index_suffix, $.inc_or_dec),
        member_suffix: $ => seq(".", choice($.ident_param, $.integer, $.operator)),
        apply_suffix: $ => seq("(", optional($.exprs), ")"),
        index_suffix: $ => seq("[", $.exprs, "]"),
        term: $ => seq(
            optional(choice($.inc_or_dec, "-", "!")),
            choice($.param_expr, $.literal, $.array_expr, $.tuple_expr, $.if_expr)
        ),
        tuple_expr: $ => seq("(", optional($.exprs), ")"),
        array_expr: $ => seq("[", optional($.exprs), "]"),
        param_expr: $ => "_",
        if_expr: $ => seq("if", "(", $.expr, ",", $.expr, optional(seq(",", $.expr)), ")"),
        literal: $ => choice($.const, "this", $.ident_param),
        const: $ => choice($.char, $.string, $.integer, $.float, "true", "false", "null"),

        inc_or_dec: $ => choice("++", "--"),
        operator: $ => prec(2, choice(
            $.infix,
            $.cast_or_query,
            "-", "~", "[]", "[]="
        )),
        cast_or_query: $ => prec.left(2, seq(
            choice("!", "?"),
            optional(seq("<", $.type_args, ">"))
        )),
        assign: $ => choice(
            "=", "<<=", ">>=", "|=", "&=", "<<<=", ">>>=", "+=", "-=", "*=", "/=", "%=", "^="
        ),
        infix: $ => choice(
            ...infix_ops.map(op => op[0])
        ),

        identifier: $ => /[a-zA-Z]\w*/,
        char: $ => seq("'", choice($.hex_char, $.printable, $.escape), "'"),
        integer: $ => /0|-?([1-9][0-9]*|0x[a-fA-F0-9]+)[uU]?[lL]?/,
        float: $ => /-?(0|([1-9]\d*))(\.\d*)?([eE][\+-]?([0]|[1-9]\d*))?[fFdD]?/,
        string: $ => seq('"', repeat(choice($.hex_char, $.printable, $.escape)), '"'),

        hex_char: $ => /\\x[0-9A-Fa-f][0-9A-Fa-f]/,
        printable: $ => choice(
            /[A-Za-z0-9]/,
            "`", "~", "!", "@", " "
        ),
        escape: $ => seq("\"", /[rnbt'"]/),
        comment: $ => token(choice(
            seq('//', /.*/),
            seq(
                '/*',
                /[^*]*\*+([^/*][^*]*\*+)*/,
                '/'
            )
        ))
    }
})