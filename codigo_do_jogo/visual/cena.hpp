#ifndef AOC_CENA_HPP
#define AOC_CENA_HPP

#include <cstddef>
#include <cstdint>

struct Jogador {
    // casa é o índice da matriz; origem fica disponível durante a transição.
    int casa, origem, direcao, fasePasso, tempoAlgema;
};

struct Guarda {
    // casa é a última posição confirmada; destino é o próximo passo planejado.
    int casa, destino, quadros, origem, direcao;
};

// Cópia do estado para desenho. O layout corresponde a "struc cena" no NASM.
// O ponteiro mapa dá acesso somente de leitura à matriz da fase.
struct Cena {
    int fase, chaves, diamante, atalhos;
    const char* aviso;
    const char* mapa;
    int tamanho, porta, estado, motivo, presos, quadros;
    Jogador dupla[2];
    Guarda guardas[2];
};

static_assert(sizeof(Cena) == 128 && offsetof(Cena, aviso) == 16 &&
              offsetof(Cena, dupla) == 48 && offsetof(Cena, guardas) == 88,
              "A interface da cena é x86 de 32 bits");

extern "C" {
void jogo_consultar(Cena* cena);
extern const int jogo_intervalo, jogo_quadros_passo, jogo_quadros_guarda;
}

constexpr int colunas = 19;
constexpr int linhas = 15;
constexpr int ladoCasa = 16;
constexpr int larguraMapa = colunas * ladoCasa;
constexpr int alturaMapa = (linhas + 2) * ladoCasa + 4;
constexpr int larguraTela = larguraMapa * 2;
constexpr int alturaTela = alturaMapa * 2;

const std::uint32_t* desenharCena(const Cena& cena);

#endif
