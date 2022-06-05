type patternParamterType string|function(string:Char char) returns boolean;

function patternPrintable(string:Char char) returns boolean {
    int codePoint = char.toCodePointInt();

    return (codePoint >= 32 && codePoint <= 126)
        || (codePoint >= 160 && codePoint <= 55295)
        || (codePoint >= 57344 && codePoint <= 65533)
        || (codePoint >= 65536 && codePoint <= 1114111)
        || codePoint is 9|10|13|133;
}

function patternJson(string:Char char) returns boolean {
    int codePoint = char.toCodePointInt();

    return (codePoint >= 32 && codePoint <= 1114111)
        || codePoint == 9;
}

function patternBom(string:Char char) returns boolean
    => char.toCodePointInt() == 65279;

function patternLineBreak(string:Char char) returns boolean
    => char.toCodePointInt() is 10|13;

function patternWhitespace(string:Char char) returns boolean
    => char is " "|"\t";

function patternDecimal(string:Char char) returns boolean
    => char is "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9";

function patternHexadecimal(string:Char char) returns boolean
    => char is "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"A"|"B"|"C"|"D"|"E"|"F"|"a"|"b"|"c"|"d"|"e"|"f";

function patternWord(string:Char char) returns boolean {
    int codePoint = char.toCodePointInt();

    return (codePoint >= 97 && codePoint <= 122)
        || (codePoint >= 65 && codePoint <= 90)
        || patternDecimal(char)
        || char == "-";
}

function patternFlowIndicator(string:Char char) returns boolean 
    => char is ","|"["|"]"|"{"|"}";

function patternIndicator(string:Char char) returns boolean 
    => char is "-"|"?"|":"|","|"["|"]"|"{"|"}"|"#"|"&"|"*"|"!"|"|"|">"|"'"|"\""|"%"|"@"|"`";

function patternUri(string:Char char) returns boolean 
    => char is "#"|";"|"/"|"?"|":"|"@"|"&"|"="|"+"|"$"|","|"_"|"."|"!"|"~"|"*"|"'"|"("|")"|"["|"]";
