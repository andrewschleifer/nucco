; **Nucco** is a quick-and-dirty, literate-programming-style documentation
; generator -- as [Docco][], [et][shocco] [al][pycco]. -- in and for [Nu][].
;
; If you've seen them, you know what it does.
;
; To use Nucco, you'll need Nu installed, as well as [NuMarkdown][];
; Download the [Nucco source][nucco] and run `nuke install`, then you can use
; `/usr/local/bin/nucco`, or `(load "Nucco:docco")` if you want to do it
; yourself.
;
; [Docco]: http://jashkenas.github.com/docco/
; [shocco]: http://rtomayko.github.com/shocco/
; [pycco]: http://fitzgen.github.com/pycco/
; [Nu]: http://programming.nu/
; [NuMarkdown]: https://github.com/timburks/numarkdown
; [nucco]: https://github.com/andrewschleifer/nucco

; _TODO:_
;
; * Pygments doesn't speak Nu. Find something else to do syntax highlighting.
; * Nu is closely married to Objective-C. We should be able to handle `.m` files, too.
; * Special treatment for nudoc @metadata.


#### Required Libraries

; We use some utility functions and the templating library from the main Nu
; framework and use NuMarkdown to format comments.
(load "Nu:nu")
(load "Nu:template")
(load "NuMarkdown:markdown")


#### Support Functions

; If there are Nu comment markers at the beginning of the string, remove them.
(function un-nu-comment (s)
    (/^\s*[#;]\s?/ replaceWithString:"" inString:s))

; Predicate test for Nu-style comments.
(function nu-comment? (s)
    (cond
        ((/^\s*[#;]/ findInString:s) t)
        (else nil)))

; Concatenate strings from a list, interleaving the requested separator.
(function with-concat (s ls)
    (cond
        ((null? ls) "")
        (else (+ (first ls) s (with-concat s (rest ls))))))

; Divide a list into sub-lists, which alternately are _equivalent_ or
; _not-equivalent_, according to a predicate function. E.g. (1 2 3 3 4 4)
; would become ((1) (2) (3 3) (4 4)) if we were testing with `even?`.
(function segregate-by (predicate ls)
    (cond
        ((null? ls) nil)
        (else (cons (match-with predicate ls)
                    (segregate-by predicate (excise-with predicate ls))))))

; Accumulate atoms that are equivalent -- according to the predicate -- to the
; first member of the list, until we locate a not-equivalent atom. This is
; used in `segregate-by` to build sub-lists.
(function match-with (predicate ls)
    (cond
        ((null? ls) nil)
        ((null? (rest ls)) ls)
        ((eq (predicate (first ls)) (predicate (first (rest ls))))
            (cons (first ls) (match-with predicate (rest ls))))
        (else (list (first ls)))))

; Discard atoms that are equivalent -- according to the predicate -- to the
; first member of the list, until we locate a not-equivalent atom. This is
; also used in `segregate-by`.
(function excise-with (predicate ls)
    (cond
        ((null? ls) nil)
        ((null? (rest ls)) nil)
        ((eq (predicate (first ls)) (predicate (first (rest ls))))
            (excise-with predicate (rest ls)))
        (else (rest ls))))

; Apply functions in a list to corresponding values in a different list,
; repeating the first list if necessary. In Nucco, we use it to apply
; different formatting to comment and code.
(function looping-map (fs ls)
    (function sub-looping-map (sub-fs ls)
        (cond
            ((null? ls) nil)
            ((null? sub-fs) (sub-looping-map fs ls))
            (else (cons ((sub-fs first) (ls first))
                        (sub-looping-map (rest sub-fs) (rest ls))))))
    (sub-looping-map fs ls))


#### Main Function

; This is the main function. It takes a string of source code, builds a list
; like (_"comment" "code" "comment" "code"_) and pours it into the
; &lt;table&gt; of an HTML template.
(function docco (title string)
    ; Split input into lines and build a list for recursing upon later.
    (set lines ((string lines) list))
    ; Discard any shebang.
    (if (/^#!/ findInString:(lines first))
        (set lines (lines rest)))
    ; Split the list into alternating comment/code sub-lists.
    (set lines (segregate-by nu-comment? lines))
    ; We need matching pairs, so if the first line is code, insert a blank
    ; comment before it.
    (unless (nu-comment? ((lines first) first))
        (set lines (cons (list ";") lines)))
    ; Format the text by uncommenting, concatenating, and Markdown-ing lines
    ; in comment sub-lists, while concatenating lines in code sub-lists.
    (set lines (looping-map
                (list
                    (do (x) (Markdown (with-concat "\n" (x map:un-nu-comment))))
                    (do (x) (with-concat "\n" x)))
                lines))
    ; Load the template from our framework bundle and evaluate it. This will
    ; parse and execute the code in the template and insert our data.
    (eval (NuTemplate codeForString:(NSString stringWithContentsOfFile:
        ((NSBundle frameworkWithName:"nucco") pathForResource:"docco" ofType:"nuhtml")
            encoding:NSUTF8StringEncoding error:nil))))
