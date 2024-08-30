pageextension 92163 Categorias extends "User Task Group"
{
    Caption = 'Categorías';
    AdditionalSearchTerms = 'Categorías';
    layout
    {
        // addafter("Description")
        // {
        //     part(Usuarios; "Usuarios x Categoría")
        //     {
        //         ApplicationArea = Basic, Suite;
        //         SubPageLink = "User Task Group Code" = field(Code);
        //     }

        // }
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
