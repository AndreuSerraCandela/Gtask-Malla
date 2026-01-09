pageextension 92163 Categorias extends "User Task Group"
{
    Caption = 'Categorías';
    AdditionalSearchTerms = 'Categorías';
    layout
    {
        addafter("Description")
        {
            field("Material Fijación"; Rec."Material Fijación")
            {
                ApplicationArea = All;
            }
            field("Tipo de Tarea"; Rec."Tipo de Tarea")
            {
                ApplicationArea = All;
            }
        }
        // modify(Control4)
        // {
        //     Visible = false;
        // }
    }
    actions
    {
        addlast(navigation)
        {
            action(Sincronizar)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Import;
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.CrearCategorias(CompanyName);
                end;
            }
        }

    }
}
pageextension 92165 CategoriasList extends "User Task Groups"
{
    Caption = 'Categorías';
    AdditionalSearchTerms = 'Categorías';
    layout
    {
        addafter("Description")
        {
            field("Tipo de Tarea"; Rec."Tipo de Tarea")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action(Sincronizar)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Import;
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.CrearCategorias(CompanyName);
                end;
            }
        }
    }
}
