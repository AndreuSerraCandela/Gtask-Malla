page 50121 "Partes Plantilla"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Partes plantilla';
    SourceTable = "Time Sheet Header";
    SourceTableView = where("Es Plantilla" = const(true));
    UsageCategory = Lists;
    CardPageId = "Parte Plantilla";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Tipo; Rec.Tipo) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Cliente; Rec.Cliente) { ApplicationArea = All; }
            }
        }
    }
}

page 50122 "Parte Plantilla"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Parte plantilla';
    SourceTable = "Time Sheet Header";
    SourceTableView = where("Es Plantilla" = const(true));

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Es Plantilla"; Rec."Es Plantilla")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Tipo; Rec.Tipo) { ApplicationArea = All; }
                field(Cliente; Rec.Cliente) { ApplicationArea = All; }
                field("Nombre Cliente"; Rec."Nombre Cliente") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
            part(Lines; "Líneas Parte de Trabajo")
            {
                ApplicationArea = All;
                SubPageLink = "Time Sheet No." = field("No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Es Plantilla" := true;
    end;
}
