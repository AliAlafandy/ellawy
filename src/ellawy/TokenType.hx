package ellawy;

enum TokenType {
    Identifier;
    StringLiteral;
    NumberLiteral;

    Local;
    Function;
    Return;
    End;
    Class;
    Import;
    True;
    False;
    Null;
    If;
    Else;
    While;
    For;
    In;
    New;
    Public;
    Private;
    Static;
    Extends;

    Plus;
    Minus;
    Star;
    Slash;
    Percent;
    Equal;
    EqualEqual;
    NotEqual;
    Less;
    LessEqual;
    Greater;
    GreaterEqual;
    And;
    Or;
    Not;

    Dot;
    Comma;
    Colon;
    Semicolon;
    Arrow;
    LeftParen;
    RightParen;
    LeftBrace;
    RightBrace;
    LeftBracket;
    RightBracket;

    EOF;
}
