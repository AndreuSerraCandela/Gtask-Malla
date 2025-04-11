/// <summary>
/// PageExtension CompantInfo (ID 80205) extends Record Company Information.
/// </summary>
pageextension 92151 CompantInfoTask extends "Company Information"
{
    layout
    {
        addlast(content)
        {
            group(Task)
            {
                field("Url Task"; Rec."Url Task")
                {
                    ApplicationArea = All;
                    Caption = 'Url Task';
                    ToolTip = 'Url Task';
                }
                field("Usuario Task"; Rec."Usuario Task")
                {
                    ApplicationArea = All;
                    Caption = 'Usuario Task';
                    ToolTip = 'Usuario Task';
                }
                field("Password Task"; Rec."Password Task")
                {
                    ApplicationArea = All;
                    Caption = 'Password Task';
                    ToolTip = 'Password Task';
                }
            }

        }


    }
    actions
    {
        addbefore("Regional Settings")
        {
            action(GenerateQRCode)
            {
                ApplicationArea = All;
                Caption = 'Generate QR Code';
                Image = BarCode;
                trigger OnAction()

                var
                    QRCodeImageTempBlob: Codeunit "Temp Blob";
                    InsStream: InStream;
                    Fichero: Text;
                    UrlQr: Text;
                begin
                    UrlQr := 'https://gtasks-app.deploy.malla.es/IdQr/12345-12345';
                    if GenerateQRCodeImage(UrlQr, QRCodeImageTempBlob) then begin
                        QRCodeImageTempBlob.CreateInStream(InsStream);
                        Fichero := 'Qr.png';
                        DownloadFromStream(InsStream, 'Qr', '*.png', 'dowload', Fichero)
                    end;
                end;


            }
        }
    }

    var
        Permisos: Boolean;
        EmpPer: Boolean;

    trigger OnAfterGetRecord()
    var
        rMem: Record "Access Control";
        Application: Record "Application Area";
    begin
        EmpPer := false;
        Application.SetRange("Company Name", CompanyName);
        If Application.FindFirst() Then EmpPer := Application.BasicHR;
        rMem.SetRange("User Security ID", UserSecurityId());
        rMem.SetRange("Role ID", 'ESP');
        Permisos := rMem.FindFirst();
    end;

    procedure GenerateQRCodeImage(SourceText: Text; QRCodeImageTempBlob: Codeunit "Temp Blob"): Boolean
    var
        MallaCrossTempBlob: Codeunit "Temp Blob";
    begin
        if SourceText = '' then
            exit(false);

        LoadMallaCrossImage(MallaCrossTempBlob);
        if GenerateQRCodeImageImpl(SourceText, QRCodeImageTempBlob) then
            exit(OverlayMallaCross(QRCodeImageTempBlob, MallaCrossTempBlob));

        exit(false);
    end;

    [TryFunction]
    local procedure GenerateQRCodeImageImpl(SourceText: Text; TempBlob: Codeunit "Temp Blob")
    var
        IBarcodeProvider: DotNet "IBarcode Provider";
        QRCodeProvider: DotNet "QRCode Provider";
        ErrorCorrectionLevel: DotNet "QRCode Error Correction Level";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        IBarcodeProvider := QRCodeProvider.QRCodeProvider();
        // encoding 65001 = UTF-8, ECI mode off.
        IBarcodeProvider.GetBarcodeStream(SourceText, OutStream, ErrorCorrectionLevel::Medium, 5, 0, 65001, false, false);
    end;

    local procedure OverlayMallaCross(QRImageTempBlob: Codeunit "Temp Blob"; MallaCrossTempBlob: Codeunit "Temp Blob"): Boolean
    var
        ratio: Decimal;
    begin
        ratio := 7 / 46;
        exit(OverlayBitmapScaledCenter(QRImageTempBlob, MallaCrossTempBlob, ratio, ratio));
    end;

    [TryFunction]
    local procedure OverlayBitmapScaledCenter(QRImageTempBlob: Codeunit "Temp Blob"; MallaCrossTempBlob: Codeunit "Temp Blob"; ratioX: Decimal; ratioY: Decimal)
    var
        QRImageBitmap: DotNet Bitmap;
        MallaCrossBitmap: DotNet Bitmap;
        Graphics: DotNet Graphics;
        ImageFormat: DotNet ImageFormat;
        Rect: DotNet Rectangle;
        InStream: InStream;
        OutStream: OutStream;
        SizeX: Integer;
        SizeY: Integer;
        OffsetX: Integer;
        OffsetY: Integer;
    begin
        QRImageTempBlob.CreateInStream(InStream);
        QRImageTempBlob.CreateOutStream(OutStream);
        QRImageBitmap := QRImageBitmap.FromStream(InStream);
        Graphics := Graphics.FromImage(QRImageBitmap);

        MallaCrossTempBlob.CreateInStream(InStream);
        MallaCrossBitmap := MallaCrossBitmap.FromStream(InStream);

        SizeX := Round(QRImageBitmap.Width() * RatioX, 1);
        SizeY := Round(QRImageBitmap.Height() * RatioY, 1);
        OffsetX := Round((QRImageBitmap.Width() - SizeX) / 2, 1);
        OffsetY := Round((QRImageBitmap.Height() - SizeY) / 2, 1);

        Graphics.DrawImage(MallaCrossBitmap, Rect.Rectangle(OffsetX, OffsetY, SizeX, SizeY));
        QRImageBitmap.Save(OutStream, ImageFormat.Bmp());

        Graphics.Dispose();
        QRImageBitmap.Dispose();
        MallaCrossBitmap.Dispose();
    end;

    local procedure LoadMallaCrossImage(TempBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(GetCrossImageBase64(), OutStream);
    end;

    procedure GetCrossImageBase64(): Text;
    begin
        exit('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');
    end;

}