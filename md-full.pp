

//Doc =       BOM? a:StartList ( Block { a = cons($$, a); } )*
//            { parse_result = reverse(a); }

Doc:
    ::BOM::? <Block>*

//Block =     BlankLine*
//            ( BlockQuote
//            | Verbatim
//            | Note
//            | Reference
//            | HorizontalRule
//            | Heading
//            | OrderedList
//            | BulletList
//            | HtmlBlock
//            | StyleBlock
//            | Para
//            | Plain )

Block:
    ::BlankLine::*
    ( BlockQuote
    | Verbatim
    | Note
    | Reference
    | HorizontalRule
    | Heading
    | OrderedList
    | BulletList
    | HtmlBlock
    | StyleBlock
    | Para()
    | Plain )

//Para =      NonindentSpace a:Inlines BlankLine+
//            { $$ = a; $$->key = PARA; }

Para:
    ::NonindentSpace:: Inlines() BlankLine+

//Plain =     a:Inlines
//            { $$ = a; $$->key = PLAIN; }
Plain:
    Inlines

//AtxInline = !Newline !(Sp '#'* Sp Newline) Inline

//AtxStart =  < ( "######" | "#####" | "####" | "###" | "##" | "#" ) >
//            { $$ = mk_element(H1 + (strlen(yytext) - 1)); }

//AtxHeading = s:AtxStart Sp a:StartList ( AtxInline { a = cons($$, a); } )+ (Sp '#'* Sp)?  Newline
//            { $$ = mk_list(s->key, a);
//              free(s); }

%token  AtxH6Start                   ######
%token  AtxH5Start                   #####
%token  AtxH4Start                   ####
%token  AtxH3Start                   ###
%token  AtxH2Start                   ##
%token  AtxH1Start                   #

#AtxHeading:
    ( ::AtxH6Start:: Inline() ::Newline:: #H6
    | ::AtxH5Start:: Inline() ::Newline:: #H5
    | ::AtxH4Start:: Inline() ::Newline:: #H4
    | ::AtxH3Start:: Inline() ::Newline:: #H3
    | ::AtxH2Start:: Inline() ::Newline:: #H2
    | ::AtxH1Start:: Inline() ::Newline:: #H1 )

//SetextHeading = SetextHeading1 | SetextHeading2

//SetextBottom1 = '='+ Newline

//SetextBottom2 = '-'+ Newline

//SetextHeading1 =  &(RawLine SetextBottom1)
//                  a:StartList ( !Endline Inline { a = cons($$, a); } )+ Sp Newline
//                  SetextBottom1 { $$ = mk_list(H1, a); }
//FIXME

//SetextHeading2 =  &(RawLine SetextBottom2)
//                  a:StartList ( !Endline Inline { a = cons($$, a); } )+ Sp Newline
//                  SetextBottom2 { $$ = mk_list(H2, a); }
//FIXME

//Heading = SetextHeading | AtxHeading
#Heading:
    AtxHeading()

//BlockQuote = a:BlockQuoteRaw
//             {  $$ = mk_element(BLOCKQUOTE);
//                $$->children = a;
//             }
BlockQuote:
    BlockQuoteRaw()

//BlockQuoteRaw =  a:StartList
//                 (( '>' ' '? Line { a = cons($$, a); } )
//                  ( !'>' !BlankLine Line { a = cons($$, a); } )*
//                  ( BlankLine { a = cons(mk_str("\n"), a); } )*
//                 )+
//                 {   $$ = mk_str_from_list(a, true);
//                     $$->key = RAW;
//                 }
//FIXME

//NonblankIndentedLine = !BlankLine IndentedLine
//FIXME

//VerbatimChunk = a:StartList
//                ( BlankLine { a = cons(mk_str("\n"), a); } )*
//                ( NonblankIndentedLine { a = cons($$, a); } )+
//                { $$ = mk_str_from_list(a, false); }

//Verbatim =     a:StartList ( VerbatimChunk { a = cons($$, a); } )+
//               { $$ = mk_str_from_list(a, false);
//                 $$->key = VERBATIM; }

//HorizontalRule = NonindentSpace
//                 ( '*' Sp '*' Sp '*' (Sp '*')*
//                 | '-' Sp '-' Sp '-' (Sp '-')*
//                 | '_' Sp '_' Sp '_' (Sp '_')*)
//                 Sp Newline BlankLine+
//                 { $$ = mk_element(HRULE); }
%token  Star                    \*
%token  Minus                   -
%token  Underscore              _
#HorizontalRule:
    ( ::Star:: Sp() ::Star:: Sp() ::Star:: (Sp() ::Star::)*
    | ::Minus:: Sp() ::Minus:: Sp() ::Minus:: (Sp() ::Minus::)*
    | ::Underscore:: Sp() ::Underscore:: Sp() ::Underscore:: (Sp() ::Underscore::)* )
    Sp() ::NewLine:: BlankLine()+

//Bullet = !HorizontalRule NonindentSpace ('+' | '*' | '-') Spacechar+
//FIXME

//BulletList = &Bullet (ListTight | ListLoose)
//             { $$->key = BULLETLIST; }


//ListTight = a:StartList
//            ( ListItemTight { a = cons($$, a); } )+
//            BlankLine* !(Bullet | Enumerator)
//            { $$ = mk_list(LIST, a); }

//ListLoose = a:StartList
//            ( b:ListItem BlankLine*
//              {   element *li;
//                  li = b->children;
//                  li->contents.str = realloc(li->contents.str, strlen(li->contents.str) + 3);
//                  strcat(li->contents.str, "\n\n");  /* In loose list, \n\n added to end of each element */
//                  a = cons(b, a);
//              } )+
//            { $$ = mk_list(LIST, a); }

//ListItem =  ( Bullet | Enumerator )
//            a:StartList
//            ListBlock { a = cons($$, a); }
//            ( ListContinuationBlock { a = cons($$, a); } )*
//            {  element *raw;
//               raw = mk_str_from_list(a, false);
//               raw->key = RAW;
//               $$ = mk_element(LISTITEM);
//               $$->children = raw;
//            }

//ListItemTight =
//            ( Bullet | Enumerator )
//            a:StartList
//            ListBlock { a = cons($$, a); }
//            ( !BlankLine
//              ListContinuationBlock { a = cons($$, a); } )*
//            !ListContinuationBlock
//            {  element *raw;
//               raw = mk_str_from_list(a, false);
//               raw->key = RAW;
//               $$ = mk_element(LISTITEM);
//               $$->children = raw;
//            }

//ListBlock = a:StartList
//            !BlankLine Line { a = cons($$, a); }
//            ( ListBlockLine { a = cons($$, a); } )*
//            { $$ = mk_str_from_list(a, false); }

//ListContinuationBlock = a:StartList
//                        ( < BlankLine* >
//                          {   if (strlen(yytext) == 0)
//                                   a = cons(mk_str("\001"), a); /* block separator */
//                              else
//                                   a = cons(mk_str(yytext), a); } )
//                        ( Indent ListBlock { a = cons($$, a); } )+
//                        {  $$ = mk_str_from_list(a, false); }

//Enumerator = NonindentSpace [0-9]+ '.' Spacechar+

//OrderedList = &Enumerator (ListTight | ListLoose)
//              { $$->key = ORDEREDLIST; }

//ListBlockLine = !BlankLine
//                !( Indent? (Bullet | Enumerator) )
//                !HorizontalRule
//                OptionallyIndentedLine

//# Parsers for different kinds of block-level HTML content.
//# This is repetitive due to constraints of PEG grammar.

//HtmlBlockOpenAddress = '<' Spnl ("address" | "ADDRESS") Spnl HtmlAttribute* '>'
//HtmlBlockCloseAddress = '<' Spnl '/' ("address" | "ADDRESS") Spnl '>'
//HtmlBlockAddress = HtmlBlockOpenAddress (HtmlBlockAddress | !HtmlBlockCloseAddress .)* HtmlBlockCloseAddress

//HtmlBlockOpenBlockquote = '<' Spnl ("blockquote" | "BLOCKQUOTE") Spnl HtmlAttribute* '>'
//HtmlBlockCloseBlockquote = '<' Spnl '/' ("blockquote" | "BLOCKQUOTE") Spnl '>'
//HtmlBlockBlockquote = HtmlBlockOpenBlockquote (HtmlBlockBlockquote | !HtmlBlockCloseBlockquote .)* HtmlBlockCloseBlockquote

//HtmlBlockOpenCenter = '<' Spnl ("center" | "CENTER") Spnl HtmlAttribute* '>'
//HtmlBlockCloseCenter = '<' Spnl '/' ("center" | "CENTER") Spnl '>'
//HtmlBlockCenter = HtmlBlockOpenCenter (HtmlBlockCenter | !HtmlBlockCloseCenter .)* HtmlBlockCloseCenter

//HtmlBlockOpenDir = '<' Spnl ("dir" | "DIR") Spnl HtmlAttribute* '>'
//HtmlBlockCloseDir = '<' Spnl '/' ("dir" | "DIR") Spnl '>'
//HtmlBlockDir = HtmlBlockOpenDir (HtmlBlockDir | !HtmlBlockCloseDir .)* HtmlBlockCloseDir

//HtmlBlockOpenDiv = '<' Spnl ("div" | "DIV") Spnl HtmlAttribute* '>'
//HtmlBlockCloseDiv = '<' Spnl '/' ("div" | "DIV") Spnl '>'
//HtmlBlockDiv = HtmlBlockOpenDiv (HtmlBlockDiv | !HtmlBlockCloseDiv .)* HtmlBlockCloseDiv

//HtmlBlockOpenDl = '<' Spnl ("dl" | "DL") Spnl HtmlAttribute* '>'
//HtmlBlockCloseDl = '<' Spnl '/' ("dl" | "DL") Spnl '>'
//HtmlBlockDl = HtmlBlockOpenDl (HtmlBlockDl | !HtmlBlockCloseDl .)* HtmlBlockCloseDl

//HtmlBlockOpenFieldset = '<' Spnl ("fieldset" | "FIELDSET") Spnl HtmlAttribute* '>'
//HtmlBlockCloseFieldset = '<' Spnl '/' ("fieldset" | "FIELDSET") Spnl '>'
//HtmlBlockFieldset = HtmlBlockOpenFieldset (HtmlBlockFieldset | !HtmlBlockCloseFieldset .)* HtmlBlockCloseFieldset

//HtmlBlockOpenForm = '<' Spnl ("form" | "FORM") Spnl HtmlAttribute* '>'
//HtmlBlockCloseForm = '<' Spnl '/' ("form" | "FORM") Spnl '>'
//HtmlBlockForm = HtmlBlockOpenForm (HtmlBlockForm | !HtmlBlockCloseForm .)* HtmlBlockCloseForm

//HtmlBlockOpenH1 = '<' Spnl ("h1" | "H1") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH1 = '<' Spnl '/' ("h1" | "H1") Spnl '>'
//HtmlBlockH1 = HtmlBlockOpenH1 (HtmlBlockH1 | !HtmlBlockCloseH1 .)* HtmlBlockCloseH1

//HtmlBlockOpenH2 = '<' Spnl ("h2" | "H2") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH2 = '<' Spnl '/' ("h2" | "H2") Spnl '>'
//HtmlBlockH2 = HtmlBlockOpenH2 (HtmlBlockH2 | !HtmlBlockCloseH2 .)* HtmlBlockCloseH2

//HtmlBlockOpenH3 = '<' Spnl ("h3" | "H3") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH3 = '<' Spnl '/' ("h3" | "H3") Spnl '>'
//HtmlBlockH3 = HtmlBlockOpenH3 (HtmlBlockH3 | !HtmlBlockCloseH3 .)* HtmlBlockCloseH3

//HtmlBlockOpenH4 = '<' Spnl ("h4" | "H4") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH4 = '<' Spnl '/' ("h4" | "H4") Spnl '>'
//HtmlBlockH4 = HtmlBlockOpenH4 (HtmlBlockH4 | !HtmlBlockCloseH4 .)* HtmlBlockCloseH4

//HtmlBlockOpenH5 = '<' Spnl ("h5" | "H5") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH5 = '<' Spnl '/' ("h5" | "H5") Spnl '>'
//HtmlBlockH5 = HtmlBlockOpenH5 (HtmlBlockH5 | !HtmlBlockCloseH5 .)* HtmlBlockCloseH5

//HtmlBlockOpenH6 = '<' Spnl ("h6" | "H6") Spnl HtmlAttribute* '>'
//HtmlBlockCloseH6 = '<' Spnl '/' ("h6" | "H6") Spnl '>'
//HtmlBlockH6 = HtmlBlockOpenH6 (HtmlBlockH6 | !HtmlBlockCloseH6 .)* HtmlBlockCloseH6

//HtmlBlockOpenMenu = '<' Spnl ("menu" | "MENU") Spnl HtmlAttribute* '>'
//HtmlBlockCloseMenu = '<' Spnl '/' ("menu" | "MENU") Spnl '>'
//HtmlBlockMenu = HtmlBlockOpenMenu (HtmlBlockMenu | !HtmlBlockCloseMenu .)* HtmlBlockCloseMenu

//HtmlBlockOpenNoframes = '<' Spnl ("noframes" | "NOFRAMES") Spnl HtmlAttribute* '>'
//HtmlBlockCloseNoframes = '<' Spnl '/' ("noframes" | "NOFRAMES") Spnl '>'
//HtmlBlockNoframes = HtmlBlockOpenNoframes (HtmlBlockNoframes | !HtmlBlockCloseNoframes .)* HtmlBlockCloseNoframes

//HtmlBlockOpenNoscript = '<' Spnl ("noscript" | "NOSCRIPT") Spnl HtmlAttribute* '>'
//HtmlBlockCloseNoscript = '<' Spnl '/' ("noscript" | "NOSCRIPT") Spnl '>'
//HtmlBlockNoscript = HtmlBlockOpenNoscript (HtmlBlockNoscript | !HtmlBlockCloseNoscript .)* HtmlBlockCloseNoscript

//HtmlBlockOpenOl = '<' Spnl ("ol" | "OL") Spnl HtmlAttribute* '>'
//HtmlBlockCloseOl = '<' Spnl '/' ("ol" | "OL") Spnl '>'
//HtmlBlockOl = HtmlBlockOpenOl (HtmlBlockOl | !HtmlBlockCloseOl .)* HtmlBlockCloseOl

//HtmlBlockOpenP = '<' Spnl ("p" | "P") Spnl HtmlAttribute* '>'
//HtmlBlockCloseP = '<' Spnl '/' ("p" | "P") Spnl '>'
//HtmlBlockP = HtmlBlockOpenP (HtmlBlockP | !HtmlBlockCloseP .)* HtmlBlockCloseP

//HtmlBlockOpenPre = '<' Spnl ("pre" | "PRE") Spnl HtmlAttribute* '>'
//HtmlBlockClosePre = '<' Spnl '/' ("pre" | "PRE") Spnl '>'
//HtmlBlockPre = HtmlBlockOpenPre (HtmlBlockPre | !HtmlBlockClosePre .)* HtmlBlockClosePre

//HtmlBlockOpenTable = '<' Spnl ("table" | "TABLE") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTable = '<' Spnl '/' ("table" | "TABLE") Spnl '>'
//HtmlBlockTable = HtmlBlockOpenTable (HtmlBlockTable | !HtmlBlockCloseTable .)* HtmlBlockCloseTable

//HtmlBlockOpenUl = '<' Spnl ("ul" | "UL") Spnl HtmlAttribute* '>'
//HtmlBlockCloseUl = '<' Spnl '/' ("ul" | "UL") Spnl '>'
//HtmlBlockUl = HtmlBlockOpenUl (HtmlBlockUl | !HtmlBlockCloseUl .)* HtmlBlockCloseUl

//HtmlBlockOpenDd = '<' Spnl ("dd" | "DD") Spnl HtmlAttribute* '>'
//HtmlBlockCloseDd = '<' Spnl '/' ("dd" | "DD") Spnl '>'
//HtmlBlockDd = HtmlBlockOpenDd (HtmlBlockDd | !HtmlBlockCloseDd .)* HtmlBlockCloseDd

//HtmlBlockOpenDt = '<' Spnl ("dt" | "DT") Spnl HtmlAttribute* '>'
//HtmlBlockCloseDt = '<' Spnl '/' ("dt" | "DT") Spnl '>'
//HtmlBlockDt = HtmlBlockOpenDt (HtmlBlockDt | !HtmlBlockCloseDt .)* HtmlBlockCloseDt

//HtmlBlockOpenFrameset = '<' Spnl ("frameset" | "FRAMESET") Spnl HtmlAttribute* '>'
//HtmlBlockCloseFrameset = '<' Spnl '/' ("frameset" | "FRAMESET") Spnl '>'
//HtmlBlockFrameset = HtmlBlockOpenFrameset (HtmlBlockFrameset | !HtmlBlockCloseFrameset .)* HtmlBlockCloseFrameset

//HtmlBlockOpenLi = '<' Spnl ("li" | "LI") Spnl HtmlAttribute* '>'
//HtmlBlockCloseLi = '<' Spnl '/' ("li" | "LI") Spnl '>'
//HtmlBlockLi = HtmlBlockOpenLi (HtmlBlockLi | !HtmlBlockCloseLi .)* HtmlBlockCloseLi

//HtmlBlockOpenTbody = '<' Spnl ("tbody" | "TBODY") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTbody = '<' Spnl '/' ("tbody" | "TBODY") Spnl '>'
//HtmlBlockTbody = HtmlBlockOpenTbody (HtmlBlockTbody | !HtmlBlockCloseTbody .)* HtmlBlockCloseTbody

//HtmlBlockOpenTd = '<' Spnl ("td" | "TD") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTd = '<' Spnl '/' ("td" | "TD") Spnl '>'
//HtmlBlockTd = HtmlBlockOpenTd (HtmlBlockTd | !HtmlBlockCloseTd .)* HtmlBlockCloseTd

//HtmlBlockOpenTfoot = '<' Spnl ("tfoot" | "TFOOT") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTfoot = '<' Spnl '/' ("tfoot" | "TFOOT") Spnl '>'
//HtmlBlockTfoot = HtmlBlockOpenTfoot (HtmlBlockTfoot | !HtmlBlockCloseTfoot .)* HtmlBlockCloseTfoot

//HtmlBlockOpenTh = '<' Spnl ("th" | "TH") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTh = '<' Spnl '/' ("th" | "TH") Spnl '>'
//HtmlBlockTh = HtmlBlockOpenTh (HtmlBlockTh | !HtmlBlockCloseTh .)* HtmlBlockCloseTh

//HtmlBlockOpenThead = '<' Spnl ("thead" | "THEAD") Spnl HtmlAttribute* '>'
//HtmlBlockCloseThead = '<' Spnl '/' ("thead" | "THEAD") Spnl '>'
//HtmlBlockThead = HtmlBlockOpenThead (HtmlBlockThead | !HtmlBlockCloseThead .)* HtmlBlockCloseThead

//HtmlBlockOpenTr = '<' Spnl ("tr" | "TR") Spnl HtmlAttribute* '>'
//HtmlBlockCloseTr = '<' Spnl '/' ("tr" | "TR") Spnl '>'
//HtmlBlockTr = HtmlBlockOpenTr (HtmlBlockTr | !HtmlBlockCloseTr .)* HtmlBlockCloseTr

//HtmlBlockOpenScript = '<' Spnl ("script" | "SCRIPT") Spnl HtmlAttribute* '>'
//HtmlBlockCloseScript = '<' Spnl '/' ("script" | "SCRIPT") Spnl '>'
//HtmlBlockScript = HtmlBlockOpenScript (!HtmlBlockCloseScript .)* HtmlBlockCloseScript

//HtmlBlockOpenHead = '<' Spnl ("head" | "HEAD") Spnl HtmlAttribute* '>'
//HtmlBlockCloseHead = '<' Spnl '/' ("head" | "HEAD") Spnl '>'
//HtmlBlockHead = HtmlBlockOpenHead (!HtmlBlockCloseHead .)* HtmlBlockCloseHead

//HtmlBlockInTags = HtmlBlockAddress
//                | HtmlBlockBlockquote
//                | HtmlBlockCenter
//                | HtmlBlockDir
//                | HtmlBlockDiv
//                | HtmlBlockDl
//                | HtmlBlockFieldset
//                | HtmlBlockForm
//                | HtmlBlockH1
//                | HtmlBlockH2
//                | HtmlBlockH3
//                | HtmlBlockH4
//                | HtmlBlockH5
//                | HtmlBlockH6
//                | HtmlBlockMenu
//                | HtmlBlockNoframes
//                | HtmlBlockNoscript
//                | HtmlBlockOl
//                | HtmlBlockP
//                | HtmlBlockPre
//                | HtmlBlockTable
//                | HtmlBlockUl
//                | HtmlBlockDd
//                | HtmlBlockDt
//                | HtmlBlockFrameset
//                | HtmlBlockLi
//                | HtmlBlockTbody
//                | HtmlBlockTd
//                | HtmlBlockTfoot
//                | HtmlBlockTh
//                | HtmlBlockThead
//                | HtmlBlockTr
//                | HtmlBlockScript
//                | HtmlBlockHead

//HtmlBlock = < ( HtmlBlockInTags | HtmlComment | HtmlBlockSelfClosing ) >
//            BlankLine+
//            {   if (extension(EXT_FILTER_HTML)) {
//                    $$ = mk_list(LIST, NULL);
//                } else {
//                    $$ = mk_str(yytext);
//                    $$->key = HTMLBLOCK;
//                }
//            }

//HtmlBlockSelfClosing = '<' Spnl HtmlBlockType Spnl HtmlAttribute* '/' Spnl '>'

//HtmlBlockType = "address" | "blockquote" | "center" | "dir" | "div" | "dl" | "fieldset" | "form" | "h1" | "h2" | "h3" |
//                "h4" | "h5" | "h6" | "hr" | "isindex" | "menu" | "noframes" | "noscript" | "ol" | "p" | "pre" | "table" |
//                "ul" | "dd" | "dt" | "frameset" | "li" | "tbody" | "td" | "tfoot" | "th" | "thead" | "tr" | "script" |
//                "ADDRESS" | "BLOCKQUOTE" | "CENTER" | "DIR" | "DIV" | "DL" | "FIELDSET" | "FORM" | "H1" | "H2" | "H3" |
//                "H4" | "H5" | "H6" | "HR" | "ISINDEX" | "MENU" | "NOFRAMES" | "NOSCRIPT" | "OL" | "P" | "PRE" | "TABLE" |
//                "UL" | "DD" | "DT" | "FRAMESET" | "LI" | "TBODY" | "TD" | "TFOOT" | "TH" | "THEAD" | "TR" | "SCRIPT"

//StyleOpen =     '<' Spnl ("style" | "STYLE") Spnl HtmlAttribute* '>'
//StyleClose =    '<' Spnl '/' ("style" | "STYLE") Spnl '>'
//InStyleTags =   StyleOpen (!StyleClose .)* StyleClose
//StyleBlock =    < InStyleTags >
//                BlankLine*
//                {   if (extension(EXT_FILTER_STYLES)) {
//                        $$ = mk_list(LIST, NULL);
//                    } else {
//                        $$ = mk_str(yytext);
//                        $$->key = HTMLBLOCK;
//                    }
//                }

//Inlines  =  a:StartList ( !Endline Inline { a = cons($$, a); }
//                        | c:Endline &Inline { a = cons(c, a); } )+ Endline?
//            { $$ = mk_list(LIST, a); }

//Inline  = Str
//        | Endline
//        | UlOrStarLine
//        | Space
//        | Strong
//        | Emph
//        | Strike
//        | Image
//        | Link
//        | NoteReference
//        | InlineNote
//        | Code
//        | RawHtml
//        | Entity
//        | EscapedChar
//        | Smart
//        | Symbol

//Space = Spacechar+
//        { $$ = mk_str(" ");
//          $$->key = SPACE; }

//Str = a:StartList < NormalChar+ > { a = cons(mk_str(yytext), a); }
//      ( StrChunk { a = cons($$, a); } )*
//      { if (a->next == NULL) { $$ = a; } else { $$ = mk_list(LIST, a); } }

//StrChunk = < (NormalChar | '_'+ &Alphanumeric)+ > { $$ = mk_str(yytext); } |
//           AposChunk

//AposChunk = &{ extension(EXT_SMART) } '\'' &Alphanumeric
//      { $$ = mk_element(APOSTROPHE); }

//EscapedChar =   '\\' !Newline < [-\\`|*_{}[\]()#+.!><] >
//                { $$ = mk_str(yytext); }

//Entity =    ( HexEntity | DecEntity | CharEntity )
//            { $$ = mk_str(yytext); $$->key = HTML; }

//Endline =   LineBreak | TerminalEndline | NormalEndline

//NormalEndline =   Sp Newline !BlankLine !'>' !AtxStart
//                  !(Line ('='+ | '-'+) Newline)
//                  { $$ = mk_str("\n");
//                    $$->key = SPACE; }

//TerminalEndline = Sp Newline Eof
//                  { $$ = NULL; }

//LineBreak = "  " NormalEndline
//            { $$ = mk_element(LINEBREAK); }

//Symbol =    < SpecialChar >
//            { $$ = mk_str(yytext); }

//# This keeps the parser from getting bogged down on long strings of '*' or '_',
//# or strings of '*' or '_' with space on each side:
//UlOrStarLine =  (UlLine | StarLine) { $$ = mk_str(yytext); }
//StarLine =      < "****" '*'* > | < Spacechar '*'+ &Spacechar >
//UlLine   =      < "____" '_'* > | < Spacechar '_'+ &Spacechar >

//Emph =      EmphStar | EmphUl

//Whitespace = Spacechar | Newline

//EmphStar =  '*' !Whitespace
//            a:StartList
//            ( !'*' b:Inline { a = cons(b, a); }
//            | b:StrongStar  { a = cons(b, a); }
//            )+
//            '*'
//            { $$ = mk_list(EMPH, a); }

//EmphUl =    '_' !Whitespace
//            a:StartList
//            ( !'_' b:Inline { a = cons(b, a); }
//            | b:StrongUl  { a = cons(b, a); }
//            )+
//            '_'
//            { $$ = mk_list(EMPH, a); }

//Strong = StrongStar | StrongUl

//StrongStar =    "**" !Whitespace
//                a:StartList
//                ( !"**" b:Inline { a = cons(b, a); })+
//                "**"
//                { $$ = mk_list(STRONG, a); }

//StrongUl   =    "__" !Whitespace
//                a:StartList
//                ( !"__" b:Inline { a = cons(b, a); })+
//                "__"
//                { $$ = mk_list(STRONG, a); }

//Strike = &{ extension(EXT_STRIKE) }
//         "~~" !Whitespace
//         a:StartList
//         ( !"~~" b:Inline { a = cons(b, a); })+
//         "~~"
//         { $$ = mk_list(STRIKE, a); }

//Image = '!' ( ExplicitLink | ReferenceLink )
//        { if ($$->key == LINK) {
//              $$->key = IMAGE;
//          } else {
//              element *result;
//              result = $$;
//              $$->children = cons(mk_str("!"), result->children);
//          } }

//Link =  ExplicitLink | ReferenceLink | AutoLink

//ReferenceLink = ReferenceLinkDouble | ReferenceLinkSingle

//ReferenceLinkDouble =  a:Label < Spnl > !"[]" b:Label
//                       {   link match;
//                           if (find_reference(&match, b->children)) {
//                               $$ = mk_link(a->children, match.url, match.title);
//                               free(a);
//                               free_element_list(b);
//                           } else {
//                               element *result;
//                               result = mk_element(LIST);
//                               result->children = cons(mk_str("["), cons(a, cons(mk_str("]"), cons(mk_str(yytext),
//                                                   cons(mk_str("["), cons(b, mk_str("]")))))));
//                               $$ = result;
//                           }
//                       }

//ReferenceLinkSingle =  a:Label < (Spnl "[]")? >
//                       {   link match;
//                           if (find_reference(&match, a->children)) {
//                               $$ = mk_link(a->children, match.url, match.title);
//                               free(a);
//                           }
//                           else {
//                               element *result;
//                               result = mk_element(LIST);
//                               result->children = cons(mk_str("["), cons(a, cons(mk_str("]"), mk_str(yytext))));
//                               $$ = result;
//                           }
//                       }

//ExplicitLink =  l:Label '(' Sp s:Source Spnl t:Title Sp ')'
//                { $$ = mk_link(l->children, s->contents.str, t->contents.str);
//                  free_element(s);
//                  free_element(t);
//                  free(l); }

//Source  = ( '<' < SourceContents > '>' | < SourceContents > )
//          { $$ = mk_str(yytext); }

//SourceContents = ( ( !'(' !')' !'>' Nonspacechar )+ | '(' SourceContents ')')*

//Title = ( TitleSingle | TitleDouble | < "" > )
//        { $$ = mk_str(yytext); }

//TitleSingle = '\'' < ( !( '\'' Sp ( ')' | Newline ) ) . )* > '\''

//TitleDouble = '"' < ( !( '"' Sp ( ')' | Newline ) ) . )* > '"'

//AutoLink = AutoLinkUrl | AutoLinkEmail

//AutoLinkUrl =   '<' < [A-Za-z]+ "://" ( !Newline !'>' . )+ > '>'
//                {   $$ = mk_link(mk_str(yytext), yytext, ""); }

//AutoLinkEmail = '<' ( "mailto:" )? < [-A-Za-z0-9+_./!%~$]+ '@' ( !Newline !'>' . )+ > '>'
//                {   char *mailto = malloc(strlen(yytext) + 8);
//                    sprintf(mailto, "mailto:%s", yytext);
//                    $$ = mk_link(mk_str(yytext), mailto, "");
//                    free(mailto);
//                }

//Reference = NonindentSpace !"[]" l:Label ':' Spnl s:RefSrc t:RefTitle BlankLine+
//            { $$ = mk_link(l->children, s->contents.str, t->contents.str);
//              free_element(s);
//              free_element(t);
//              free(l);
//              $$->key = REFERENCE; }

//Label = '[' ( !'^' &{ extension(EXT_NOTES) } | &. &{ !extension(EXT_NOTES) } )
//        a:StartList
//        ( !']' Inline { a = cons($$, a); } )*
//        ']'
//        { $$ = mk_list(LIST, a); }

//RefSrc = < Nonspacechar+ > 
//         { $$ = mk_str(yytext); 
//           $$->key = HTML; }

//RefTitle =  ( RefTitleSingle | RefTitleDouble | RefTitleParens | EmptyTitle )
//            { $$ = mk_str(yytext); }

//EmptyTitle = < "" >

//RefTitleSingle = Spnl '\'' < ( !( '\'' Sp Newline | Newline ) . )* > '\''

//RefTitleDouble = Spnl '"' < ( !('"' Sp Newline | Newline) . )* > '"'

//RefTitleParens = Spnl '(' < ( !(')' Sp Newline | Newline) . )* > ')'

//References = a:StartList
//             ( b:Reference { a = cons(b, a); } | SkipBlock )*
//             { references = reverse(a); }

//Ticks1 = "`" !'`'
//Ticks2 = "``" !'`'
//Ticks3 = "```" !'`'
//Ticks4 = "````" !'`'
//Ticks5 = "`````" !'`'

//Code = ( Ticks1 Sp < ( ( !'`' Nonspacechar )+ | !Ticks1 '`'+ | !( Sp Ticks1 ) ( Spacechar | Newline !BlankLine ) )+ > Sp Ticks1
//       | Ticks2 Sp < ( ( !'`' Nonspacechar )+ | !Ticks2 '`'+ | !( Sp Ticks2 ) ( Spacechar | Newline !BlankLine ) )+ > Sp Ticks2
//       | Ticks3 Sp < ( ( !'`' Nonspacechar )+ | !Ticks3 '`'+ | !( Sp Ticks3 ) ( Spacechar | Newline !BlankLine ) )+ > Sp Ticks3
//       | Ticks4 Sp < ( ( !'`' Nonspacechar )+ | !Ticks4 '`'+ | !( Sp Ticks4 ) ( Spacechar | Newline !BlankLine ) )+ > Sp Ticks4
//       | Ticks5 Sp < ( ( !'`' Nonspacechar )+ | !Ticks5 '`'+ | !( Sp Ticks5 ) ( Spacechar | Newline !BlankLine ) )+ > Sp Ticks5
//       )
//       { $$ = mk_str(yytext); $$->key = CODE; }

//RawHtml =   < (HtmlComment | HtmlBlockScript | HtmlTag) >
//            {   if (extension(EXT_FILTER_HTML)) {
//                    $$ = mk_list(LIST, NULL);
//                } else {
//                    $$ = mk_str(yytext);
//                    $$->key = HTML;
//                }
//            }

//BlankLine =     Sp Newline

//Quoted =        '"' (!'"' .)* '"' | '\'' (!'\'' .)* '\''
//HtmlAttribute = (AlphanumericAscii | '-')+ Spnl ('=' Spnl (Quoted | (!'>' Nonspacechar)+))? Spnl
//HtmlComment =   "<!--" (!"-->" .)* "-->"
//HtmlTag =       '<' Spnl '/'? AlphanumericAscii+ Spnl HtmlAttribute* '/'? Spnl '>'
//Eof =           !.
//Spacechar =     ' ' | '\t'
%token  Spacechar               ' '|'\t'
//Nonspacechar =  !Spacechar !Newline .
//Newline =       '\n' | '\r' '\n'?
%token  Newline                 \n|\r\n?
//Sp =            Spacechar*
//Spnl =          Sp (Newline Sp)?
//SpecialChar =   '~' | '*' | '_' | '`' | '&' | '[' | ']' | '(' | ')' | '<' | '!' | '#' | '\\' | '\'' | '"' | ExtendedSpecialChar
//NormalChar =    !( SpecialChar | Spacechar | Newline ) .
//Alphanumeric = [0-9A-Za-z] | '\200' | '\201' | '\202' | '\203' | '\204' | '\205' | '\206' | '\207' | '\210' | '\211' | '\212' | '\213' | '\214' | '\215' | '\216' | '\217' | '\220' | '\221' | '\222' | '\223' | '\224' | '\225' | '\226' | '\227' | '\230' | '\231' | '\232' | '\233' | '\234' | '\235' | '\236' | '\237' | '\240' | '\241' | '\242' | '\243' | '\244' | '\245' | '\246' | '\247' | '\250' | '\251' | '\252' | '\253' | '\254' | '\255' | '\256' | '\257' | '\260' | '\261' | '\262' | '\263' | '\264' | '\265' | '\266' | '\267' | '\270' | '\271' | '\272' | '\273' | '\274' | '\275' | '\276' | '\277' | '\300' | '\301' | '\302' | '\303' | '\304' | '\305' | '\306' | '\307' | '\310' | '\311' | '\312' | '\313' | '\314' | '\315' | '\316' | '\317' | '\320' | '\321' | '\322' | '\323' | '\324' | '\325' | '\326' | '\327' | '\330' | '\331' | '\332' | '\333' | '\334' | '\335' | '\336' | '\337' | '\340' | '\341' | '\342' | '\343' | '\344' | '\345' | '\346' | '\347' | '\350' | '\351' | '\352' | '\353' | '\354' | '\355' | '\356' | '\357' | '\360' | '\361' | '\362' | '\363' | '\364' | '\365' | '\366' | '\367' | '\370' | '\371' | '\372' | '\373' | '\374' | '\375' | '\376' | '\377'
//AlphanumericAscii = [A-Za-z0-9]
//Digit = [0-9]
//BOM = "\357\273\277"
%token  BOM                     "\357\273\277"

//HexEntity =     < '&' '#' [Xx] [0-9a-fA-F]+ ';' >
//DecEntity =     < '&' '#' [0-9]+ > ';' >
//CharEntity =    < '&' [A-Za-z0-9]+ ';' >

//NonindentSpace =    "   " | "  " | " " | ""
%token  NonindentSpace          ' '{0,3}

//Indent =            "\t" | "    "
//IndentedLine =      Indent Line
//OptionallyIndentedLine = Indent? Line

//# StartList starts a list data structure that can be added to with cons:
//StartList = &.
//            { $$ = NULL; }

//Line =  RawLine
//        { $$ = mk_str(yytext); }
//RawLine = ( < (!'\r' !'\n' .)* Newline > | < .+ > Eof )

//SkipBlock = HtmlBlock
//          | ( !'#' !SetextBottom1 !SetextBottom2 !BlankLine RawLine )+ BlankLine*
//          | BlankLine+
//          | RawLine

//# Syntax extensions

//ExtendedSpecialChar = &{ extension(EXT_SMART) } ('.' | '-' | '\'' | '"')
//                    | &{ extension(EXT_NOTES) } ( '^' )

//Smart = &{ extension(EXT_SMART) }
//        ( Ellipsis | Dash | SingleQuoted | DoubleQuoted | Apostrophe )

//Apostrophe = '\''
//             { $$ = mk_element(APOSTROPHE); }

//Ellipsis = ("..." | ". . .")
//           { $$ = mk_element(ELLIPSIS); }

//Dash = EmDash | EnDash

//EnDash = '-' &Digit
//         { $$ = mk_element(ENDASH); }

//EmDash = ("---" | "--")
//         { $$ = mk_element(EMDASH); }

//SingleQuoteStart = '\'' !(Spacechar | Newline)

//SingleQuoteEnd = '\'' !Alphanumeric

//SingleQuoted = SingleQuoteStart
//               a:StartList
//               ( !SingleQuoteEnd b:Inline { a = cons(b, a); } )+
//               SingleQuoteEnd
//               { $$ = mk_list(SINGLEQUOTED, a); }

//DoubleQuoteStart = '"'

//DoubleQuoteEnd = '"'

//DoubleQuoted =  DoubleQuoteStart
//                a:StartList
//                ( !DoubleQuoteEnd b:Inline { a = cons(b, a); } )+
//                DoubleQuoteEnd
//                { $$ = mk_list(DOUBLEQUOTED, a); }

//NoteReference = &{ extension(EXT_NOTES) }
//                ref:RawNoteReference
//                {   element *match;
//                    if (find_note(&match, ref->contents.str)) {
//                        $$ = mk_element(NOTE);
//                        assert(match->children != NULL);
//                        $$->children = match->children;
//                        $$->contents.str = 0;
//                    } else {
//                        char *s;
//                        s = malloc(strlen(ref->contents.str) + 4);
//                        sprintf(s, "[^%s]", ref->contents.str);
//                        $$ = mk_str(s);
//                        free(s);
//                    }
//                }

//RawNoteReference = "[^" < ( !Newline !']' . )+ > ']'
//                   { $$ = mk_str(yytext); }

//Note =          &{ extension(EXT_NOTES) }
//                NonindentSpace ref:RawNoteReference ':' Sp
//                a:StartList
//                ( RawNoteBlock { a = cons($$, a); } )
//                ( &Indent RawNoteBlock { a = cons($$, a); } )*
//                {   $$ = mk_list(NOTE, a);
//                    $$->contents.str = strdup(ref->contents.str);
//                }

//InlineNote =    &{ extension(EXT_NOTES) }
//                "^["
//                a:StartList
//                ( !']' Inline { a = cons($$, a); } )+
//                ']'
//                { $$ = mk_list(NOTE, a);
//                  $$->contents.str = 0; }

//Notes =         a:StartList
//                ( b:Note { a = cons(b, a); } | SkipBlock )*
//                { notes = reverse(a); }

//RawNoteBlock =  a:StartList
//                    ( !BlankLine OptionallyIndentedLine { a = cons($$, a); } )+
//                ( < BlankLine* > { a = cons(mk_str(yytext), a); } )
//                {   $$ = mk_str_from_list(a, true);
//                    $$->key = RAW;
//                }

//%%


