; Keywords
(declaration_keyword) @keyword

; Declaration identifiers
(block_declaration
  id: (identifier) @type)

(macro_declaration
  name: (identifier) @function.macro)

; Flag identifiers
(flag_declaration
  (identifier) @constant)

; Literals
(string) @string
(date) @number
(duration) @number.float
(time) @number
(number) @number

; References
(macro_reference) @function.macro
(macro_body) @string.special
(task_reference) @variable

; Comments
(line_comment) @comment
(block_comment) @comment

; Punctuation
["{" "}"] @punctuation.bracket
["(" ")"] @punctuation.bracket
["-" "," "~"] @operator
["!"] @operator
