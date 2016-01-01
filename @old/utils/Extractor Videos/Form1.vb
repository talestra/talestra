Imports System.IO

Public Class Form1

    Dim Dato(3) As Byte
    Dim NumVideo As Short
    Dim Cadena(16383) As Byte

    Private Sub Button1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button1.Click
        ODlg.ShowDialog()
        TextBox1.Text = ODlg.FileName
    End Sub

    Private Sub Button2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button2.Click

        If Not File.Exists(TextBox1.Text) Then
            MsgBox("El archivo no existe.")
            Exit Sub
        End If

        Button2.Text = "Extrayendo..."
        Button2.Enabled = False

        NumVideo = 0

        Dim fs1 As New FileStream(TextBox1.Text, FileMode.Open, FileAccess.Read)
        
        fs1.Read(Dato, 0, 4)
        fs1.Seek(-4, SeekOrigin.Current)

        If Dato(0) <> 0 Or Dato(1) <> 0 Or Dato(2) <> 1 Or Dato(3) <> 186 Then
            fs1.Close()
            MsgBox("No parece ser un archivo válido.")
            Button2.Text = "Extraer"
            Button2.Enabled = True
            Exit Sub
        End If

        SDlg.ShowDialog()

        If SDlg.FileName = "" Then
            Button2.Text = "Extraer"
            Button2.Enabled = True
            fs1.Close()
            Exit Sub
        End If

        ProgressBar1.Maximum = fs1.Length

        Do While fs1.Position < fs1.Length

            fs1.Read(Dato, 0, 4)
            fs1.Seek(-4, SeekOrigin.Current)

            If Dato(0) = 0 And Dato(1) = 0 And Dato(2) = 1 And Dato(3) = 186 Then

                Dim fs2 As New FileStream(SDlg.FileName & Format(NumVideo, "0000") & ".mpg", FileMode.Create, FileAccess.Write)

                Do

                    Application.DoEvents()

                    ProgressBar1.Value = fs1.Position

                    fs1.Read(Cadena, 0, 16384)
                    fs2.Write(Cadena, 0, 16384)

                    fs1.Read(Dato, 0, 4)
                    fs1.Seek(-4, SeekOrigin.Current)

                    If Dato(0) = 0 And Dato(1) = 0 And Dato(2) = 1 And Dato(3) = 185 Then
                        fs2.Write(Dato, 0, 4)
                        fs2.Seek(0, SeekOrigin.Begin)
                        NumVideo = NumVideo + 1
                        fs2.Close()
                        Exit Do
                    End If
                Loop
            Else

                fs1.Seek(4, SeekOrigin.Current)

            End If

        Loop

        fs1.Close()

        Button2.Text = "Extraer"
        Button2.Enabled = True
        MsgBox("Se ha terminado el proceso.")
        ProgressBar1.Value = 0
    End Sub
End Class