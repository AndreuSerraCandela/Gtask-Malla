/// <summary>
/// TableExtension Tareasusuarios (ID 90103) extends Record User Task.
/// </summary>
tableextension 92103 Tareasusuarios extends "User Task"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Supervisor; guid)
        {
            Caption = 'Supervisor';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));
            ValidateTableRelation = false;
            trigger OnLookup()
            var
                User: Record UsuariosGtask;
            begin
                User.ChangeCompany('Malla Publicidad');
                If Page.RunModal(Page::UsuariosGtask, User) = Action::LookupOK then
                    Supervisor := user."Id Usuario";
            end;

        }

        field(50015; "Supervisor User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Supervisor")));
            Caption = 'Nombre Supervisor';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50002; "No."; Code[20])
        {

        }
        field(50003; "Line No."; Integer)
        {

        }
        field(50012; Id_record; RecordId)
        {

        }
        field(50004; OrdenFijacion; Integer)
        {
            Caption = 'Orden Fijación';
        }
        field(50005; "Job No."; Code[20])
        {
            TableRelation = Job."No.";
        }
        //departamento
        field(50006; Departamento; Text[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }
        //servicio
        field(50007; Servicio; Text[20])
        {
            Caption = 'Servicio';
            DataClassification = ToBeClassified;
            TableRelation = "Work Center"."No.";
        }
        field(50013; Reserva; Integer) { }

        modify("Assigned To")
        {
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        modify("User Task Group Assigned To")
        {
            Caption = 'Categoría';

        }
        field(50008; Categoría; Code[20])
        {
            Caption = 'User Task Group Assigned To';
            DataClassification = CustomerContent;
            TableRelation = "User Task Group".Code;

            trigger OnValidate()
            var
                Categorias: Record "User Task Group Member";
            begin
                Categorias.ChangeCompany('Malla Publicidad');
                "User Task Group Assigned To" := Categoría;
                Categorias.SetRange("User Task Group Code", Categoría);
                Categorias.SetRange(Departamento, Departamento);
                Categorias.SetRange(Responsable, true);
                if Categorias.FindFirst() then
                    "Assigned To" := Categorias."User Security ID";
                "User Task Group Assigned To" := "Categoría";

            end;
        }
        field(50009; Estado; Enum "Task Enum")
        {
            Caption = 'Estado';
            DataClassification = ToBeClassified;
        }
        field(50010; "Fecha Comunicado Cambio"; DateTime)
        {
            Caption = 'Fecha Comunicado Cambio';
            DataClassification = ToBeClassified;
        }
        field(50011; "Fecha Cambio"; DateTime)
        {
            Caption = 'Fecha Comunicado Cambio';
            DataClassification = ToBeClassified;
        }
        field(50014; Mentioned; BLOB)
        {
            Caption = 'Mencionados';
            SubType = Memo;
        }
        field(50016; fastPhoto; Boolean)
        {
            Caption = 'Foto rápida';
            DataClassification = ToBeClassified;
        }
        field(50017; Resource; Code[20])
        {
            Caption = 'Recurso';
            DataClassification = ToBeClassified;
        }
        field(50018; IdQr; Text[100])
        { }
        field(50019; OrdenRetirada; Boolean)
        {
            Caption = 'Orden Fijación';
        }
        field(50020; Frecuencia; DateFormula)
        {
            ObsoleteState = Removed;

        }
        field(50021; DependenciaCreada; Boolean)
        {
            Caption = 'Dependencia Creada';
        }
        field(50022; ZonaLimpieza; Integer)
        {
            Caption = 'Zona Limpieza';
            DataClassification = ToBeClassified;
            TableRelation = "Zonas Limpieza".Id;
        }
        field(50023; TipoTarea; Text[50])
        {
            Caption = 'Emplazamiento';
            DataClassification = ToBeClassified;
            TableRelation = Emplazamientos."Nº Emplazamiento";
        }
        field(50024; TareaAnterior; Integer)
        {
            Caption = 'Tarea Anterior';
            DataClassification = ToBeClassified;
        }
        field(50025; EsPeriodica; Boolean)
        {
            Caption = 'Es Periodica';
            DataClassification = ToBeClassified;
        }
        //Crear Parte de Trabajo
        field(50026; CrearParte; Boolean)
        {
            Caption = 'Crear Parte de Trabajo';
            DataClassification = ToBeClassified;
        }
    }
    trigger OnAfterDelete()
    var
        Gtask: Codeunit GTask;
    begin
        Gtask.DeleteTarea(Rec.Id_Tarea);
    end;

    procedure GetMentioned(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo(Mentioned));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetMentioned(StreamText: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Mentioned);
        Description.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(StreamText);
        if Modify(true) then;
    end;

    procedure CalcularProximoDiaLimpieza(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): Date
    var
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        FechaBusqueda: Date;
        MaxIteraciones: Integer;
    begin
        // Si hay reglas de periodicidad definidas en la tabla, usarlas (solo días laborables L-V y sin festivos)
        PeriodicidadZona.SetRange("Id Zona Limpieza", ZonaLimpieza.Id);
        if PeriodicidadZona.FindFirst() then begin
            FechaBusqueda := Fecha;
            MaxIteraciones := 366;
            while MaxIteraciones > 0 do begin
                FechaBusqueda := FechaBusqueda + 1;
                if CoincideConPeriodicidadZona(FechaBusqueda, ZonaLimpieza.Id) then
                    exit(FechaBusqueda);
                MaxIteraciones -= 1;
            end;
            if not EsDiaLaborable(FechaBusqueda) then begin
                while not EsDiaLaborable(FechaBusqueda) do
                    FechaBusqueda := FechaBusqueda + 1;
            end;

            exit(0D); // No se encontró próxima fecha en el año
        end;
        // Respaldo: lógica antigua con Periodicidad/Periodicidad Invierno si existen en la zona
        // exit(CalcularProximoDiaLimpiezaLegacy(ZonaLimpieza, Fecha));
    end;

    // local procedure CalcularProximoDiaLimpiezaLegacy(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): Date
    // var
    //     FechaActual: Date;
    //     IsWinter: Boolean;
    //     Periodicidad: DateFormula;
    // begin
    //     if Date2DMY(Fecha, 2) in [1, 2, 3, 10, 11, 12] then
    //         IsWinter := true;
    //     if IsWinter then
    //         FechaActual := CalcDate(ZonaLimpieza."Periodicidad Invierno", Fecha)
    //     else
    //         FechaActual := CalcDate(ZonaLimpieza."Periodicidad", Fecha);
    //     exit(FechaActual);
    // end;

    // procedure CalcularPeriodicidad(ZonaLimpieza: Record "Zonas Limpieza"; Fecha: Date): DateFormula
    // var
    //     IsWinter: Boolean;
    //     Periodicidad: DateFormula;
    // begin
    //     if Date2DMY(Fecha, 2) in [1, 2, 3, 10, 11, 12] then
    //         IsWinter := true;
    //     if IsWinter then
    //         Periodicidad := ZonaLimpieza."Periodicidad Invierno"
    //     else
    //         Periodicidad := ZonaLimpieza."Periodicidad";
    //     exit(Periodicidad);
    // end;

    local procedure EsDiaLaborable(Fecha: Date): Boolean
    var
        Calendario: Record "Base Calendar Change";
    begin
        Calendario.ChangeCompany('Malla Publicidad');
        Calendario.SetRange("Date", Fecha);
        If Calendario.FindFirst() then begin
            If Calendario.Nonworking Then exit(false);
            If (Calendario.Day = Calendario.Day::Sunday) or (Calendario.Day = Calendario.Day::Saturday) Then exit(false);
        end;
        exit(true);
    end;

    local procedure CoincideConPeriodicidadZona(Fecha: Date; IdZonaLimpieza: Integer): Boolean
    var
        PeriodicidadZona: Record "Periodicidad Zona Limpieza";
        DiaSemana: Integer;
        DiaDelMes: Integer;
        Mes: Integer;
        DíaSemanaEnum: Enum "Día Semana Limpieza";
    begin
        PeriodicidadZona.SetRange("Id Zona Limpieza", IdZonaLimpieza);
        if not PeriodicidadZona.FindSet() then
            exit(false);
        DiaSemana := Date2DWY(Fecha, 1);
        DiaDelMes := Date2DMY(Fecha, 1);
        Mes := Date2DMY(Fecha, 2); // meses invierno: 11, 12, 1, 2, 3
        repeat
            if not AplicaLineaEnFecha(PeriodicidadZona.Temporada, Mes) then
                continue;
            case PeriodicidadZona."Tipo Periodicidad" of
                PeriodicidadZona."Tipo Periodicidad"::"Día semanal":
                    if (PeriodicidadZona."Día Semana" <> DíaSemanaEnum::Ninguno) and
                       CoincideDiaSemana(DiaSemana, PeriodicidadZona."Día Semana")
                    then
                        exit(true);
                PeriodicidadZona."Tipo Periodicidad"::"Día del mes":
                    if (PeriodicidadZona."Día del mes" >= 1) and (PeriodicidadZona."Día del mes" <= 31) and
                       (DiaDelMes = PeriodicidadZona."Día del mes")
                    then
                        exit(true);
            end;
        until PeriodicidadZona.Next() = 0;
        exit(false);
    end;

    local procedure AplicaLineaEnFecha(Temporada: Enum "Temporada Limpieza"; Mes: Integer): Boolean
    begin
        case Temporada of
            Temporada::Todas:
                exit(true);
            Temporada::Invierno:
                exit(Mes in [1, 2, 11, 12]); // nov, dic, ene, feb
            Temporada::Verano:
                exit(Mes in [3, 4, 5, 6, 7, 8, 9, 10]); // mar, abr, may, jun, jul, ago, sep, oct
            else
                exit(true);
        end;
    end;

    local procedure CoincideDiaSemana(DiaSemanaNum: Integer; DíaSemana: Enum "Día Semana Limpieza"): Boolean
    begin
        case DíaSemana of
            DíaSemana::Lunes:
                exit(DiaSemanaNum = 1);
            DíaSemana::Martes:
                exit(DiaSemanaNum = 2);
            DíaSemana::Miércoles:
                exit(DiaSemanaNum = 3);
            DíaSemana::Jueves:
                exit(DiaSemanaNum = 4);
            DíaSemana::Viernes:
                exit(DiaSemanaNum = 5);
            else
                exit(false);
        end;
    end;

    procedure CrearDependencia(): Boolean
    var
        FechaActual: Date;
        DiaSemana: Integer;
        DiasAñadir: Integer;
        MaxDias: Integer;
        IsWinter: Boolean;
        Periodicidad: DateFormula;
        Gtask: Codeunit Gtask;
        RecorId: RecordId;
        RecRef: RecordRef;
        Descripcion: Text;
        ZonaLimpieza: Record "Zonas Limpieza";
        FechaInicio: Date;
    begin
        // Salir si la tarea no está asociada a una zona de limpieza (evita error en Get y crea dependencia solo para tareas de limpieza)
        if Rec.ZonaLimpieza = 0 then
            exit(false);
        if not ZonaLimpieza.Get(Rec.ZonaLimpieza) then
            exit(false);
        // Salir si no hay registro vinculado (evita error en RecRef.Get)
        RecorId := Rec.Id_record;
        if not RecRef.Get(RecorId) then
            exit(false);

        Descripcion := Rec.GetDescription();
        FechaInicio := Rec.CalcularProximoDiaLimpieza(ZonaLimpieza, WorkDate());
        If Gtask.CrearTareaLimpieza(Rec.TipoTarea, RecRef, Rec.Title, Rec.ZonaLimpieza, Descripcion
                                     , false, '', FechaInicio, true, Rec.Id) then begin
            Rec.Get(Rec.Id);
            Rec.DependenciaCreada := true;
            Rec.Estado := Rec.Estado::Finalizado;
            Rec.Modify(true);
            exit(true);
        end;
        exit(false);
    end;
}
tableextension 90109 Tareascomercial extends "To-do"
{
    fields
    {
        field(50000; Id_Tarea; Text[250])
        {
            Caption = 'Id_tarea';
            DataClassification = ToBeClassified;
        }
        field(50001; Responsable; guid)
        {
            Caption = 'Responsable';
            DataClassification = ToBeClassified;
            TableRelation = User."User Security ID";//WHERE("License Type" = CONST("Full User"));


        }
        field(50002; Categoria; Code[20])
        {
            Caption = 'Categoría';
            DataClassification = ToBeClassified;
            TableRelation = "User Task Group"."Code";
        }
        field(50003; Departamento; Code[20])
        {
            Caption = 'Departamento';
            DataClassification = ToBeClassified;
            TableRelation = "Responsibility Center"."Code";
        }



    }
    trigger OnAfterModify()
    var
        Gtastk: Codeunit GTask;
    begin
        if ("Start Time" <> 0T) and (Id_Tarea = '') then
            Gtastk.CrearTareaTodo(Rec);
    end;

}