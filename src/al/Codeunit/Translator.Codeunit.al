codeunit 95000 Translator
{
    SingleInstance = true;

    var
        Translator: ControlAddIn Translator;

    procedure Initialize(Translator2: ControlAddIn Translator)
    begin
        Translator := Translator2;
    end;

    procedure Update();
    begin
        Translator.Update();
    end;

    procedure SaveCaptured(TranslatedText: Text; AreaOfText: Text): Integer
    var
        DB: Record TranslationDB;
        T: Text;
        A: Text;
    begin
        T := DelChr(TranslatedText, '<>', ' ');
        T := DelChr(T, '<>', '\t');
        T := DelChr(T, '<>', '\r');
        T := DelChr(T, '<>', '\n');

        if T = '' then
            exit(0);

        DB.Init();
        DB."Translated Text" := CopyStr(T, 1, MaxStrLen(DB."Translated Text"));
        DB."Area of text" := CopyStr(A, 1, MaxStrLen(DB."Area of text"));
        DB.Insert(true);

        exit(DB."Entry No.");
    end;
}