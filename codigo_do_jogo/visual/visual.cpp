#include <windows.h>
#include <mmsystem.h>
#include "cena.hpp"
#include <cstring>

extern "C" {
// Evita que o compilador C++ mude os nomes das funções exportadas pelo NASM.
void jogo_iniciar();
void jogo_tecla(unsigned tecla);
void jogo_soltar(unsigned tecla);
int jogo_tick();
int jogo_clicar(unsigned coordenadas);
extern const char musica_pcm[];
extern const DWORD musica_bytes;
extern int jogo_estado;
extern unsigned jogo_tentativa;
}

namespace {

constexpr UINT_PTR timerJogo = 1;
constexpr char classe[] = "PatifePilantraAOC";
constexpr char titulo[] = "Patife e Pilantra";

HWAVEOUT dispositivo{};
WAVEHDR faixa{};

void abrirMusica() {
    // PCM estéreo de 48 kHz e 16 bits, incorporado pelo NASM.
    WAVEFORMATEX formato{WAVE_FORMAT_PCM, 2, 48000, 192000, 4, 16, 0};
    if (waveOutOpen(&dispositivo, WAVE_MAPPER, &formato, 0, 0, CALLBACK_NULL)
        != MMSYSERR_NOERROR) return;
    faixa.lpData = const_cast<char*>(musica_pcm);
    faixa.dwBufferLength = musica_bytes;
    faixa.dwFlags = WHDR_BEGINLOOP | WHDR_ENDLOOP;
    faixa.dwLoops = MAXDWORD;
    if (waveOutPrepareHeader(dispositivo, &faixa, sizeof(faixa)) != MMSYSERR_NOERROR) {
        waveOutClose(dispositivo);
        dispositivo = nullptr;
    }
}

void sincronizarMusica() {
    static int estadoAnterior = -1;
    static unsigned tentativaAnterior = 0;
    if (!dispositivo) return;
    const bool novaTentativa = tentativaAnterior != jogo_tentativa;
    if (!novaTentativa && estadoAnterior == jogo_estado) return;
    if (jogo_estado == 0) {
        if (novaTentativa || estadoAnterior != 1) {
            waveOutReset(dispositivo);
            waveOutWrite(dispositivo, &faixa, sizeof(faixa));
        }
        waveOutRestart(dispositivo);
    } else if (jogo_estado == 1) {
        waveOutPause(dispositivo);
    } else {
        waveOutReset(dispositivo);
    }
    estadoAnterior = jogo_estado;
    tentativaAnterior = jogo_tentativa;
}

void fecharMusica() {
    if (!dispositivo) return;
    waveOutReset(dispositivo);
    waveOutUnprepareHeader(dispositivo, &faixa, sizeof(faixa));
    waveOutClose(dispositivo);
    dispositivo = nullptr;
}

void texto(HDC dc, int x, int y, const char* valor) {
    TextOutA(dc, x, y, valor, static_cast<int>(std::strlen(valor)));
}

void apresentar(HDC dc) {
    // Consulta as regras, desenha sobre um buffer e entrega a imagem ao Windows.
    Cena painel{};
    jogo_consultar(&painel);
    const auto* pixels = desenharCena(painel);
    BITMAPINFO bitmap{};
    bitmap.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmap.bmiHeader.biWidth = larguraTela;
    bitmap.bmiHeader.biHeight = -alturaTela;
    bitmap.bmiHeader.biPlanes = 1;
    bitmap.bmiHeader.biBitCount = 32;
    SetDIBitsToDevice(dc, 0, 0, larguraTela, alturaTela, 0, 0, 0,
                      alturaTela, pixels, &bitmap, DIB_RGB_COLORS);
    if (painel.estado == estadoMenu) return;

    SelectObject(dc, GetStockObject(SYSTEM_FIXED_FONT));
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, RGB(220, 232, 246));
    static const char* const cabecalhos[] = {
        "01  PATIFE E PILANTRA | PRIS\xC3O",
        "02  PATIFE E PILANTRA | MUSEU",
        "03  PATIFE E PILANTRA | PRAIA",
        "04  PATIFE E PILANTRA | BONUS",
    };
    texto(dc, 8, 7, cabecalhos[painel.fase]);
    if (painel.atalhos) texto(dc, 420, 7, "TESTE F1-F4");
    if (painel.fase == faseBonus) {
        char status[] = "DIAMANTES: 0/9";
        status[11] += painel.diamantesBonus;
        texto(dc, 280, 7, status);
    }
    texto(dc, 8, alturaTela - 33, painel.aviso);
}

LRESULT CALLBACK procedimento(HWND janela, UINT mensagem, WPARAM tecla, LPARAM dados) {
    switch (mensagem) {
    case WM_KEYDOWN:
        // O motor controla teclas seguradas; ignora a repetição do Windows.
        if (!(dados & (1L << 30))) {
            jogo_tecla(static_cast<unsigned>(tecla));
            sincronizarMusica();
            InvalidateRect(janela, nullptr, FALSE);
        }
        return 0;
    case WM_KEYUP:
        jogo_soltar(static_cast<unsigned>(tecla));
        return 0;
    case WM_LBUTTONDOWN:
        // O Assembly valida a fase e a área clicada antes de trocar de mapa.
        if (jogo_clicar(static_cast<unsigned>(dados))) {
            sincronizarMusica();
            InvalidateRect(janela, nullptr, FALSE);
            return 0;
        }
        break;
    case WM_TIMER:
        if (tecla == timerJogo) {
            // O relógio é da janela. A lógica do tick continua em Assembly.
            if (jogo_tick()) InvalidateRect(janela, nullptr, FALSE);
            sincronizarMusica();
            return 0;
        }
        break;
    case WM_PAINT: {
        PAINTSTRUCT pintura;
        const HDC dc = BeginPaint(janela, &pintura);
        apresentar(dc);
        EndPaint(janela, &pintura);
        return 0;
    }
    case WM_DESTROY:
        fecharMusica();
        KillTimer(janela, timerJogo);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcA(janela, mensagem, tecla, dados);
}

}

int WINAPI WinMain(HINSTANCE instancia, HINSTANCE, LPSTR, int exibir) {
    WNDCLASSA configuracao{};
    configuracao.style = CS_HREDRAW | CS_VREDRAW;
    configuracao.lpfnWndProc = procedimento;
    configuracao.hInstance = instancia;
    configuracao.hCursor = LoadCursorA(nullptr, IDC_ARROW);
    configuracao.lpszClassName = classe;
    if (!RegisterClassA(&configuracao)) return 1;

    constexpr DWORD estilo = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
    RECT area{0, 0, larguraTela, alturaTela};
    if (!AdjustWindowRect(&area, estilo, FALSE)) return 1;
    jogo_iniciar();
    const HWND janela = CreateWindowExA(0, classe, titulo, estilo,
        CW_USEDEFAULT, CW_USEDEFAULT, area.right - area.left, area.bottom - area.top,
        nullptr, nullptr, instancia, nullptr);
    if (!janela) return 1;
    abrirMusica();
    sincronizarMusica();
    ShowWindow(janela, exibir);
    if (!SetTimer(janela, timerJogo, jogo_intervalo, nullptr)) {
        DestroyWindow(janela);
        return 1;
    }

    MSG mensagem;
    int resultado;
    while ((resultado = GetMessageA(&mensagem, nullptr, 0, 0)) > 0) {
        TranslateMessage(&mensagem);
        DispatchMessageA(&mensagem);
    }
    return resultado < 0 ? 1 : static_cast<int>(mensagem.wParam);
}
