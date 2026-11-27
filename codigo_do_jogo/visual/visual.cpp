#include <windows.h>
#include "cena.hpp"
#include <cstring>

extern "C" {
// Evita que o compilador C++ mude os nomes das funções exportadas pelo NASM.
void jogo_iniciar();
void jogo_tecla(unsigned tecla);
void jogo_soltar(unsigned tecla);
int jogo_tick();
int jogo_clicar(unsigned coordenadas);
}

namespace {

constexpr UINT_PTR timerJogo = 1;
constexpr char classe[] = "PatifePilantraAOC";
constexpr char titulo[] = "Patife e Pilantra";

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
            InvalidateRect(janela, nullptr, FALSE);
        }
        return 0;
    case WM_KEYUP:
        jogo_soltar(static_cast<unsigned>(tecla));
        return 0;
    case WM_LBUTTONDOWN:
        // O Assembly valida a fase e a área clicada antes de trocar de mapa.
        if (jogo_clicar(static_cast<unsigned>(dados))) {
            InvalidateRect(janela, nullptr, FALSE);
            return 0;
        }
        break;
    case WM_TIMER:
        if (tecla == timerJogo) {
            // O relógio é da janela. A lógica do tick continua em Assembly.
            if (jogo_tick()) InvalidateRect(janela, nullptr, FALSE);
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
