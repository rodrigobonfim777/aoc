"""Extrai as portas fornecidas, preservando proporcoes, em 16x16 e 32x32."""

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BOXES = {
    "porta_azul_fechada": (30, 50, 536, 796),
    "porta_azul_aberta": (30, 50, 536, 796),
}

for name, box in BOXES.items():
    image = Image.open(ROOT / f"assets/{name}_referencia.png").convert("RGBA").crop(box)
    width, height = image.size
    pixels = image.load()
    queue = deque((x, y) for x in range(width) for y in (0, height - 1))
    queue.extend((x, y) for y in range(height) for x in (0, width - 1))
    visited = set()
    while queue:
        x, y = queue.popleft()
        if not (0 <= x < width and 0 <= y < height) or (x, y) in visited:
            continue
        visited.add((x, y))
        r, g, b, a = pixels[x, y]
        if a and max(r, g, b) > 22 and not (min(r, g, b) > 150 and max(r, g, b) - min(r, g, b) < 35):
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    # Descarta pontos isolados do fundo, sem tocar nos detalhes da figura.
    mask = image.getchannel("A")
    seen = set()
    components = []
    for y in range(height):
        for x in range(width):
            if (x, y) in seen or not mask.getpixel((x, y)):
                continue
            component = []
            queue = deque([(x, y)])
            seen.add((x, y))
            while queue:
                point = queue.popleft()
                component.append(point)
                px, py = point
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and mask.getpixel((nx, ny)):
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    largest = max(components, key=len)
    cleaned = Image.new("RGBA", image.size)
    for point in largest:
        cleaned.putpixel(point, image.getpixel(point))
    cleaned = cleaned.crop(cleaned.getbbox())
    for size, suffix in ((16, ""), (32, "_detalhado")):
        scaled = cleaned.copy()
        scaled.thumbnail((size, size), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (size, size))
        tile.paste(scaled, ((size - scaled.width) // 2, size - scaled.height))
        # O renderizador atual aceita BGRA opaco ou zero, sem mistura de alfa.
        tile.putdata([(*p[:3], 255) if p[3] >= 128 else (0, 0, 0, 0) for p in tile.getdata()])
        tile.save(ROOT / f"assets/{name}{suffix}.png")
        data = tile.tobytes("raw", "BGRA")
        (ROOT / f"assets/{name}{suffix}.bgra").write_bytes(data)
