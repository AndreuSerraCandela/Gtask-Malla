tableextension 50102 "Orden Fijacion Ext" extends "Orden fijación"
{
    fields
    {
        field(50000; TieneFotos; Boolean)
        {
            Caption = 'Tiene Fotos';
            FieldClass = FlowField;
            CalcFormula = exist("Document Attachment" where("Table ID" = const(Database::"Orden fijación"),
                                                                "Line No." = field("Nº Reserva"),
                                                                "ID_Doc" = field("Nº Orden"),
                                                                "File Name" = filter('*jpg')));
            Editable = false;
        }
        field(50001; EstadoTarea; Enum "Task Enum")
        {
            Caption = 'Estado de la Tarea';
            FieldClass = FlowField;
            CalcFormula = lookup("User Task".Estado where(OrdenFijacion = field("Nº Orden"), Reserva = field("Nº Reserva")));
            Editable = false;
        }
        field(50002; TieneTask; Boolean)
        {
            Caption = 'Tiene Tarea';
            FieldClass = FlowField;
            CalcFormula = exist("User Task" where(OrdenFijacion = field("Nº Orden"), Reserva = field("Nº Reserva")));
            Editable = false;
        }
        field(50003; TieneQR; Boolean)
        {
            Caption = 'Tiene QR';
            FieldClass = FlowField;
            CalcFormula = exist("Imagenes Orden fijación" where("Nº Orden" = field("Nº Orden"), "Nº Imagen" = field("Nº Qr"),
                                                                "Es QR" = const(true)));
            Editable = false;
        }

        field(50006; "Tipo Recurso"; Text[30])
        {
            Caption = 'Tipo Recurso';
            FieldClass = FlowField;
            CalcFormula = lookup(Resource."Tipo Recurso" where("No." = field("Nº Recurso")));
            Editable = false;
        }
        field(50007; "Equipo"; Guid)
        {
            Caption = 'Equipo';
            FieldClass = FlowField;
            CalcFormula = lookup("User Task"."Assigned To" where(Reserva = field("Nº Reserva")));
            Editable = false;
        }
        field(50018; "Cerrada Medios"; Boolean)
        {
            ObsoleteState = Removed;

        }
        field(50019; "Estado Medios"; Option)
        {
            OptionMembers = " ",Retirada,Finalizado;
            OptionCaption = ' ,Retirada,Finalizado';
        }
        modify(Retirar)
        {
            trigger OnBeforeValidate()
            begin
                if Rec.Retirar then Rec."Estado Medios" := Rec."Estado Medios"::Retirada;
            end;
        }
        modify(Retirada)
        {
            trigger OnBeforeValidate()
            begin
                if Rec.Retirada then Rec."Estado Medios" := Rec."Estado Medios"::Retirada;

            end;
        }


    }

    procedure "Fecha Inicio Reserva"(): Date
    var
        Reserva: Record Reserva;
    begin
        if Rec.Empresa <> '' then
            Reserva.ChangeCompany(Rec.Empresa);
        if Reserva.Get(Rec."Nº Reserva") then
            exit(Reserva."Fecha inicio")
        else
            exit(0D);
    end;

    procedure "Fecha Fin Reserva"(): Date
    var
        Reserva: Record Reserva;
    begin
        if Rec.Empresa <> '' then
            Reserva.ChangeCompany(Rec.Empresa);
        if Reserva.Get(Rec."Nº Reserva") then
            exit(Reserva."Fecha fin")
        else
            exit(0D);
    end;

    procedure Nombre(): Text[50]
    var
        User: Record User;
    begin
        calcfields(Equipo);
        if User.Get(Rec.Equipo) then
            exit(User."Full Name")
        else
            exit('');
    end;

    procedure DescripcionRecurso(): Text
    var
        Recurso: Record Resource;
    begin
        If Recurso.Get(Rec."Nº Recurso") then
            exit(Recurso.Name)
        else
            exit('');
    end;

    procedure DescripcionCampaña(): Text
    var
        Job: Record Job;
    begin
        if Rec.Empresa <> '' Then Job.ChangeCompany(Rec.Empresa);
        if Job.Get(Rec."Nº Proyecto") then
            exit(Job.Description)
        else
            exit('');
    end;
}
tableextension 50103 "Imagenes Orden fijación Ext" extends "Imagenes Orden fijación"
{
    fields
    {
        modify("Nº Orden")
        {
            TableRelation = if ("Es Incidencia" = const(false)) "Cab Orden fijación"."Nº Orden"
            else
            if ("Es incidencia" = const(true)) "Incidencias"."Nº Orden";
        }
    }
}