#include "cena.hpp"
#include "arte_embutida.hpp"

#include <algorithm>
#include <cstring>

namespace {

using Pixel = std::uint32_t;
constexpr Pixel alfa = 0xff000000;
constexpr Pixel rgb = 0x00ffffff;
constexpr int tamanhoAtor = 32;
constexpr int atorNaTela = 36;
constexpr int quadrosDupla = 4;
constexpr int quadrosPolicial = 7;
constexpr int tempoQuedaAlgema = 16;

struct Ponto { int x, y; };

// Superfície de desenho em memória. A matriz de colisão fica no Assembly.
struct Superficie {
    Pixel* pixels;
    int largura;

    void retangulo(int x, int y, int w, int h, Pixel cor) const {
        for (int linha = y; linha < y + h; ++linha)
            std::fill_n(pixels + linha * largura + x, w, cor);
    }

    void sprite(Ponto p, const Pixel* origem, int tamanho, int lado,
                Pixel mascara = alfa, Pixel cor = 0xffffffff) const {
        // Amostragem pelo vizinho mais próximo mantém a borda da pixel art.
        // Nos sprites com alfa, um pixel transparente deixa o piso intacto.
        const bool escala = tamanho != lado;
        for (int y = 0; y < lado; ++y) {
            const auto* linha = origem + (escala ? y * tamanho / lado : y) * tamanho;
            auto* destino = pixels + (p.y + y) * largura + p.x;
            for (int x = 0; x < lado; ++x) {
                const auto pixel = linha[escala ? x * tamanho / lado : x];
                if (pixel & mascara) destino[x] = pixel & cor;
            }
        }
    }

    void bloco(Ponto p, const Pixel* origem) const {
        sprite(p, origem, 16, 16, 0xffffffff);
    }

    void tile(Ponto p, const Pixel* atlas, int indice) const {
        sprite(p, atlas + indice * 16 * 16, 16, 16, alfa, rgb);
    }
};

Pixel pixelsMapa[larguraMapa * alturaMapa];
Pixel pixelsTela[larguraTela * alturaTela];
const Superficie mapa{pixelsMapa, larguraMapa};
const Superficie tela{pixelsTela, larguraTela};

Ponto casa(int i, int lado = ladoCasa) {
    // Resto = coluna; quociente = linha. Soma uma linha para reservar o HUD.
    return {i % colunas * lado, (i / colunas + 1) * lado};
}

Pixel escurecer(Pixel cor) { return (cor & 0x00fefefe) >> 1; }

char tileVisivel(const Cena& cena, int i) {
    const char tipo = cena.mapa[i];
    if (tipo == 'T') {
        for (int jogador = 0; jogador < 2; ++jogador)
            if ((cena.presos & (1 << jogador)) && cena.dupla[jogador].casa == i)
                return '.';  // o sprite de queda/prisão já inclui as algemas
    }
    return tipo;
}

bool parede(const Cena& cena, int i, char tipo) {
    // Esta escolha é visual. A regra para entrar na casa fica em movimento.inc.
    return tipo == '#' || (cena.fase == 1 && i == 5 * colunas);
}

const Pixel* recorteParede(int fase, int i) {
    // O atlas lista topo, rodapé, laterais e blocos internos nessa ordem.
    const int x = i % colunas, y = i / colunas;
    int quadro;
    if (y == 0) quadro = x;
    else if (y == linhas - 1) quadro = colunas + x;
    else if (x == 0) quadro = 2 * colunas + y - 1;
    else if (x == colunas - 1) quadro = 2 * colunas + linhas + y - 3;
    else quadro = 2 * colunas + 2 * (linhas - 2) + (fase == 0 && x == colunas / 2);
    return (fase == 0 ? arte::paredes_cadeia : arte::paredes_museu) + quadro * 32 * 32;
}

void desenharCasa(const Cena& cena, int i) {
    const char tipo = tileVisivel(cena, i);
    const auto p = casa(i);
    if (parede(cena, i, tipo)) {
        if (cena.fase == 2) mapa.tile(p, arte::tiles_praia, 1);
        else mapa.sprite(p, recorteParede(cena.fase, i), 32, 16);
        return;
    }
    // Sobre o piso entram objetos como a vitrine, a grade e as alavancas.
    switch (cena.fase) {
    case 0: mapa.bloco(p, i % colunas < colunas / 2 ? arte::piso_esquerdo : arte::piso_direito); break;
    case 1: mapa.tile(p, arte::tiles_museu, 0); break;
    case 2: mapa.tile(p, arte::tiles_praia, 0); break;
    }

    switch (tipo) {
    case 'D': {
        if (cena.fase == 0) mapa.bloco(p, arte::pedra_diamante);
        if (cena.fase == 1) mapa.tile(p, arte::tiles_museu, 1);
        if (cena.fase == 2) mapa.tile(p, arte::tiles_praia, 2);
        const Pixel* const cores[] = {arte::diamante_azul, arte::diamante_roxo, arte::diamante_verde};
        mapa.bloco(p, cena.diamante ? arte::vitrine_vazia : cores[cena.fase]);
        return;
    }
    case 'T':
        if (cena.estado != 0) mapa.sprite(p, arte::algema_detalhada, 32, 16);
        return;
    case 'G':
        if (!(cena.chaves & 1)) mapa.tile(p, arte::tiles_icones, 0);
        return;
    case 'a': mapa.tile(p, arte::tiles_icones, 1 + bool(cena.chaves & 1)); return;
    case 'b': mapa.tile(p, arte::tiles_icones, 3 + bool(cena.chaves & 2)); return;
    }

    if (cena.fase == 1) {
        constexpr char decoracoes[] = "spvcf";
        if (tipo == 's') mapa.bloco(p, arte::dinossauro_museu);
        else if (tipo >= '1' && tipo <= '3')
            mapa.bloco(p, arte::dinossauro_museu + (tipo - '0') * 256);
        else if (tipo >= '4' && tipo <= '7')
            mapa.bloco(p, arte::esfinge_museu + (tipo - '4') * 256);
        else if (tipo >= 'I' && tipo <= 'L')
            mapa.bloco(p, arte::pensador_museu + (tipo - 'I') * 256);
        else if (tipo >= 'N' && tipo <= 'Q')
            mapa.bloco(p, arte::mesa_museu + (tipo - 'N') * 256);
        else if (const char* tile = std::strchr(decoracoes, tipo))
            mapa.tile(p, arte::tiles_museu, 2 + static_cast<int>(tile - decoracoes));
    }
    if (cena.fase == 2) {
        switch (tipo) {
        case 'u': mapa.tile(p, arte::tiles_praia, 3); break;
        case 'q': mapa.tile(p, arte::tiles_praia, 4); break;
        case 'k': mapa.tile(p, arte::tiles_praia, 5); break;
        case 'f': mapa.tile(p, arte::tiles_praia, 6); break;
        }
    }
}

void desenharPorta(const Cena& cena, bool detalhada) {
    const bool aberta = cena.chaves & 2;
    if (detalhada) {
        const auto* artePorta = aberta ? arte::porta_azul_aberta_detalhado : arte::porta_azul_fechada_detalhado;
        tela.sprite(casa(cena.porta, 32), artePorta, 32, 32);
    } else {
        const auto* artePorta = aberta ? arte::porta_azul_aberta : arte::porta_azul_fechada;
        mapa.sprite(casa(cena.porta), artePorta, 16, 16);
    }
}

Ponto interpolar(int destino, int origem, int restantes, int total) {
    // A lógica já escolheu a casa. Aqui calculamos só a posição aparente
    // entre a origem e o destino, usando os ticks que ainda faltam.
    auto p = casa(destino);
    const auto anterior = casa(origem);
    p.x += (anterior.x - p.x) * restantes / total;
    p.y += (anterior.y - p.y) * restantes / total;
    return p;
}

void desenharAtor(const Pixel* atlas, int quadro, Ponto p, bool detalhado) {
    const int escala = detalhado ? 2 : 1;
    const int lado = atorNaTela / 2 * escala;
    p.x = p.x * escala - (lado - ladoCasa * escala) / 2;
    p.y = p.y * escala - (lado - ladoCasa * escala);
    (detalhado ? tela : mapa).sprite(p, atlas + quadro * tamanhoAtor * tamanhoAtor,
                                     tamanhoAtor, lado);
}

void desenharGuarda(const Guarda& guarda, bool detalhado) {
    int quadro = guarda.direcao * quadrosPolicial;
    if (guarda.origem != guarda.destino && guarda.quadros)
        quadro += 1 + (jogo_quadros_guarda - guarda.quadros) * 6 / jogo_quadros_guarda;
    desenharAtor(arte::policial, quadro,
                 interpolar(guarda.destino, guarda.origem, guarda.quadros, jogo_quadros_guarda),
                 detalhado);
}

void desenharJogador(const Cena& cena, int i, bool detalhado) {
    const Jogador& jogador = cena.dupla[i];
    int quadro = jogador.direcao * quadrosDupla;
    if (cena.presos & (1 << i)) {
        // O atlas contém a queda e o personagem preso depois da caminhada.
        const int tempo = jogador.tempoAlgema;
        if (tempo < tempoQuedaAlgema)
            quadro = cena.estado == 3 ? 20 : 16 + tempo / 4;
        else quadro = 20 + (tempo - tempoQuedaAlgema) / 8 % quadrosDupla;
    } else if (cena.quadros && jogador.origem != jogador.casa) {
        quadro += (jogador.fasePasso + (jogo_quadros_passo - cena.quadros) * 2 / jogo_quadros_passo) % quadrosDupla;
    }
    desenharAtor(i == 0 ? arte::pilantra : arte::patife, quadro,
                 interpolar(jogador.casa, jogador.origem, cena.quadros, jogo_quadros_passo),
                 detalhado);
}

void textoCentral(const char* texto, int y, int escala = 1, bool pequena = false) {
    // A fonte armazena cada linha do caractere como uma máscara de bits.
    const auto* fonte = pequena ? arte::fonte_pequena : arte::fonte_normal;
    const int largura = pequena ? 4 : 5, altura = pequena ? 6 : 7, passo = largura + 1;
    int x = (larguraMapa - static_cast<int>(std::strlen(texto)) * passo * escala) / 2;
    for (; *texto; ++texto, x += passo * escala) {
        const int indice = *texto - 32;
        if (indice < 0 || indice > 58) continue;
        for (int linha = 0; linha < altura; ++linha) {
            for (int coluna = 0; coluna < largura; ++coluna) {
                if (fonte[indice * altura + linha] & (1 << (largura - 1 - coluna)))
                    mapa.retangulo(x + coluna * escala, y + linha * escala,
                                   escala, escala, 0xdce6f2);
            }
        }
    }
}

void desenharCaixa(const Cena& cena) {
    std::transform(pixelsMapa, pixelsMapa + larguraMapa * alturaMapa, pixelsMapa, escurecer);
    mapa.retangulo(16, 83, 276, 116, 0x070e19);
    mapa.retangulo(14, 80, 276, 116, 0x945465);
    mapa.retangulo(16, 81, 272, 1, 0xcd8797);
    mapa.retangulo(16, 83, 272, 111, 0x0c1828);
    mapa.retangulo(34, 144, 236, 34, 0x2d4566);
    mapa.retangulo(34, 144, 236, 1, 0x3a567b);
    if (cena.estado == 1) {
        textoCentral("JOGO PAUSADO", 94, 2);
        textoCentral("A PARTIDA ESTA PAUSADA", 122);
        textoCentral("APERTE P PARA CONTINUAR", 151);
        textoCentral("R PARA REINICIAR A FASE", 165);
    } else if (cena.estado == 3) {
        static const char* const causas[] = {
            "A TENTATIVA TERMINOU", "O GUARDA CAPTUROU O PILANTRA", "O GUARDA CAPTUROU A PATIFE",
            "OS DOIS FICARAM PRESOS NAS ALGEMAS", "PATIFE PRESA NAS ALGEMAS",
        };
        textoCentral("GAME OVER", 94, 2);
        textoCentral(causas[cena.motivo], 122);
        textoCentral("APERTE R PARA REINICIAR", 151);
        textoCentral("E JOGAR NOVAMENTE", 165);
    } else {
        textoCentral("FASE CONCLUIDA", 94, 2);
        if (cena.fase == 0) {
            textoCentral("OS LADROES CONSEGUIRAM FUGIR", 118, 1, true);
            textoCentral("DA CADEIA COM O DIAMANTE", 130, 1, true);
        } else if (cena.fase == 1) {
            textoCentral("A DUPLA FUGIU DO MUSEU COM A JOIA", 118, 1, true);
        } else {
            textoCentral("A DUPLA ESCAPOU DA PRAIA COM A JOIA", 118, 1, true);
        }
        if (cena.fase < 2) {
            textoCentral("PRESSIONE ENTER PARA IR", 151, 1, true);
            textoCentral("PARA A PROXIMA FASE", 165, 1, true);
        } else textoCentral("APERTE R PARA JOGAR DE NOVO", 151, 1, true);
    }
}

void ampliarMapa() {
    for (int y = 0; y < alturaMapa; ++y) {
        auto* superior = pixelsTela + 2 * y * larguraTela;
        auto* inferior = superior + larguraTela;
        for (int x = 0; x < larguraMapa; ++x) {
            const auto pixel = pixelsMapa[y * larguraMapa + x];
            superior[2 * x] = superior[2 * x + 1] = pixel;
            inferior[2 * x] = inferior[2 * x + 1] = pixel;
        }
    }
}

void exposicao(const Cena& cena, int linha, int coluna, const Pixel* sprite, bool opaca) {
    const Ponto p = casa(linha * colunas + coluna, 32);
    for (int y = p.y; y < p.y + 64; ++y) {
        for (int x = p.x; x < p.x + 64; ++x) {
            auto pixel = *sprite++;
            if (!opaca && !(pixel & alfa)) continue;
            if (cena.estado != 0) {
                if (!opaca && x >= 28 && x < 584 && y >= 160 && y < 398) continue;
                pixel = escurecer(pixel);
            }
            pixelsTela[y * larguraTela + x] = pixel;
        }
    }
}

}

const std::uint32_t* desenharCena(const Cena& cena) {
    std::fill_n(pixelsMapa, larguraMapa * alturaMapa, 0x171d30);
    for (int i = 0; i < cena.tamanho; ++i) desenharCasa(cena, i);
    if (cena.estado != 0) {
        // Nas telas de pausa, vitória e derrota, a caixa cobre a cena escurecida.
        desenharPorta(cena, false);
        for (int i = 0; i < cena.tamanho; ++i) {
            for (const auto& guarda : cena.guardas)
                if (guarda.destino == i) desenharGuarda(guarda, false);
            if (cena.dupla[0].casa == i) desenharJogador(cena, 0, false);
            else if (cena.dupla[1].casa == i) desenharJogador(cena, 1, false);
        }
        desenharCaixa(cena);
    }
    ampliarMapa();
    // Os sprites detalhados entram na resolução final para manter a nitidez.
    if (cena.estado == 0 && cena.fase != 2) {
        for (int i = 0; i < cena.tamanho; ++i)
            if (parede(cena, i, cena.mapa[i]))
                tela.sprite(casa(i, 32), recorteParede(cena.fase, i), 32, 32);
    }
    if (cena.fase == 1) {
        exposicao(cena, 1, 1, arte::dinossauro_museu_detalhado, true);
        exposicao(cena, 12, 16, arte::esfinge_museu_detalhado, true);
        exposicao(cena, 10, 4, arte::pensador_museu_detalhado, false);
        exposicao(cena, 3, 15, arte::mesa_museu_detalhado, false);
    }
    if (cena.estado == 0) {
        desenharPorta(cena, true);
        for (int i = 0; i < cena.tamanho; ++i)
            if (tileVisivel(cena, i) == 'T') tela.sprite(casa(i, 32), arte::algema_detalhada, 32, 32);
        for (const auto& guarda : cena.guardas)
            if (guarda.casa >= 0) desenharGuarda(guarda, true);
        desenharJogador(cena, 0, true);
        desenharJogador(cena, 1, true);
    }
    return pixelsTela;
}
