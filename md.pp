//Central/Hoa/Core/Bin/hoa compiler:pp -v dump hoa-markdown/md.pp hoa-markdown/test.md

%token  AtxH6Start                   ######
%token  AtxH5Start                   #####
%token  AtxH4Start                   ####
%token  AtxH3Start                   ###
%token  AtxH2Start                   ##
%token  AtxH1Start                   #
%token  Star                         \*
%token  Minus                        -
%token  Underscore                   _
%token  Spacechar                    [\h\t]
%token  Newline                      \n|\r\n?
%token  BOM                          "\357\273\277"
%token  NonindentSpace               \h{1,3}

%token  RawLine                      [^\r\n]+

Doc:
    ::BOM::? Block()*

Block:
    BlankLine()*
    ( Heading()
    | Para()
    )

#Para:
    ::NonindentSpace::? Inlines() BlankLine()+

BlankLine:
    Sp() ::Newline::

#AtxHeading:
    (
      ::AtxH6Start:: Sp() Inline() ::Newline:: #H6
    | ::AtxH5Start:: Sp() Inline() ::Newline:: #H5
    | ::AtxH4Start:: Sp() Inline() ::Newline:: #H4
    | ::AtxH3Start:: Sp() Inline() ::Newline:: #H3
    | ::AtxH2Start:: Sp() Inline() ::Newline:: #H2
    | ::AtxH1Start:: Sp() Inline() ::Newline:: #H1
    )

Heading:
    AtxHeading()

Inlines:
    Inline()+

Inline:
    ( <RawLine>
    | BlankLine()
    )

Sp:
    ::Spacechar::*
