page 50126 "Líneas Parte de Trabajo"
{
    PageType = ListPart;
    SourceTable = "Time Sheet Line";
    Caption = 'Líneas Parte de Trabajo';
    Editable = true;
    AutoSplitKey = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número de línea.';
                    Visible = false;
                }


                field(Tipo; Rec.Tipo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el tipo de elemento.';
                }
                field(No; Rec.No)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el número del elemento.';
                    trigger OnValidate()
                    var
                        Item: Record Item;
                        Resource: Record Resource;
                    begin
                        if Rec.Description = '' Then begin
                            case Rec.Tipo of
                                Rec.Tipo::Producto:
                                    begin
                                        if Item.Get(Rec.No) then
                                            Rec.Description := Item.Description;
                                    end;
                                Rec.Tipo::Recurso:
                                    begin
                                        if Resource.Get(Rec.No) then
                                            Rec.Description := Resource.Name;
                                    end;
                            end;
                        end;
                    end;
                }
                field(Description2; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción de la línea.';
                    StyleExpr = Negrita;

                }


                // Cantidad
                field(Cantidad; Rec.Cantidad)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica la cantidad de la línea.';

                }
                field(Precio; Rec.Precio)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el precio de la línea.';

                }
                // Dto
                field(Dto; Rec.Dto)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el dto de la línea.';

                }
                // Importe
                field(Importe; Rec.Importe)
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el importe de la línea.';

                }


            }
        }
    }

    actions
    {
        area(processing)
        {

            action("Ver Adjuntos")
            {
                ApplicationArea = All;
                Caption = 'Ver Adjuntos';
                Image = Attach;
                ToolTip = 'Muestra los adjuntos relacionados con esta línea.';
                RunObject = Page "Document Attachment Details";
                RunPageLink = "Table ID" = const(Database::"Time Sheet Line"),
                              "No." = field("Time Sheet No."),
                              "Line No." = field("Line No.");
                Promoted = true;
            }

        }
    }

    var
        Negrita: Text;
        EsEmt: Boolean;

    trigger OnAfterGetRecord()
    var
    begin
        if Rec."Job Line No." <> 0 then
            Negrita := 'Strong'
        else
            Negrita := 'Standard';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        if TimeSheetHeader.Get(Rec."Time Sheet No.") then begin
            Rec."Job No." := TimeSheetHeader.Proyecto;
            Rec.Type := Rec.Type::Job;
        end;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
        JobPlan: Record "Job Planning Line";
    begin
        if TimeSheetHeader.Get(Rec."Time Sheet No.") then begin
            If TimeSheetHeader."Resource No." = '' then begin
                JobPlan.SetRange("Job No.", Rec."Job No.");
                JobPlan.SetRange(Type, JobPlan.Type::Resource);
                If JobPlan.FindFirst() then
                    TimeSheetHeader."Resource No." := JobPlan."No.";
                TimeSheetHeader.Modify();
            end;

        end;
        exit(true);
    end;

}