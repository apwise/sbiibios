#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#define CHARS 16
#define LINES 8
#define SCALE 4

#define ROM_SIZE 2048
uint8_t *rom;
uint8_t *rom2;

static void readfile(const char *filename)
{
  rom = malloc(ROM_SIZE);
  assert(rom);

  FILE *fp = fopen(filename, "rb");
  if (!fp) {
    fprintf(stderr, "Failed to open \"%s\" for reading\n", filename);
    exit(1);
  }

  for (unsigned i = 0; i<ROM_SIZE; i++) {
    int ch = getc(fp);
    if (ch == EOF) {
      fprintf(stderr, "Unexpected EOF in \"%s\" (at %d)\n",
              filename, i);
      exit(1);
    }
    rom[i] = ch;
  }

  int ch = getc(fp);
  if (ch != EOF) {
      fprintf(stderr, "Warning: \"%s\" larger than expected (%d)\n",
              filename, ROM_SIZE);
  }
  
  fclose(fp);
}

static void write_char(FILE *fp, unsigned code, unsigned line, bool colour, unsigned scale)
{
  assert(code < 128);
  assert(line < 10);
  uint8_t byte = rom[(code * 16) + line];
  for (unsigned p = 0; p < 7; p++) {
    for (unsigned s = 0; s < scale; s++) {
      bool bit = (byte >> p) & 1;
      if (colour) {
        char c = ((bit) ? '1' : '0');
      fprintf(fp, "%c %c %c", c, c, c);
      } else {
        fprintf(fp, "%c", ((bit) ? '0' : '1'));
      }
      if ((p != 6) || (s != (scale-1)))
        fprintf(fp, " ");
    }
  }
}

static void write_image(FILE *fp, unsigned scale)
{
  fprintf(fp, "P1\n");
  fprintf(fp, "%d %d\n", CHARS*7*scale, LINES*10*scale);
  for (unsigned l = 0; l < LINES; l++) {
    for (unsigned sl = 0; sl<10; sl++) {
      for (unsigned s = 0; s<scale; s++) {
        for (unsigned c = 0; c < CHARS; c++) {
          write_char(fp, (l * CHARS) + c, sl, false, scale);
          if (c != (CHARS-1))
            fprintf(fp, " ");
        }
        fprintf(fp, "\n");
      }
    }
  }
}

static void write_colour_image(FILE *fp, unsigned hscale, unsigned vscale)
{
  unsigned h = CHARS*(7*hscale+1)+1;
  fprintf(fp, "P3\n");
  fprintf(fp, "%d %d\n", h, LINES*(10*vscale+1)+1);
  fprintf(fp, "%d\n", 1);

  for (unsigned i = 0; i < h; i++) {
      fprintf(fp, "0 0 1\n");
  }

  for (unsigned l = 0; l < LINES; l++) {
    for (unsigned sl = 0; sl<10; sl++) {
      for (unsigned s = 0; s<vscale; s++) {
        fprintf(fp, "0 0 1\n");
        for (unsigned c = 0; c < CHARS; c++) {
          write_char(fp, (l * CHARS) + c, sl, true, hscale);
          fprintf(fp, " 0 0 1\n");
        }
      }
    }

    for (unsigned i = 0; i < h; i++) {
      fprintf(fp, "0 0 1\n");
    }
    
  }
}

static void invert()
{
  rom2 = malloc(ROM_SIZE);
  assert(rom2);
  assert(rom);
  for (unsigned i = 0; i<ROM_SIZE; i++) {
    rom2[i] = ~rom[i];
  }
}

static void writefile(const char *filename)
{
  assert(rom2);
  FILE *fp = fopen(filename, "wb");
  if (!fp) {
    fprintf(stderr, "Failed to open \"%s\" for writing\n", filename);
    exit(1);
  }

  for (unsigned i = 0; i<ROM_SIZE; i++) {
    putc(rom2[i], fp);
  }
  
  fclose(fp);
}


int main(int argc, const char **argv)
{
  if (argc != 2) {
    fprintf(stderr, "usage: %s <filename>\n", argv[0]);
    exit(1);
  }
  readfile(argv[1]);
  {
    FILE *fp = fopen("image.pbm", "w");
    assert(fp);
    write_image(fp, SCALE);
    fclose(fp);
  }
  {
    FILE *fp = fopen("image.ppm", "w");
    assert(fp);
    write_colour_image(fp, 4, 7);
    fclose(fp);
  }


  invert();
  writefile("inverted.bin");
}
