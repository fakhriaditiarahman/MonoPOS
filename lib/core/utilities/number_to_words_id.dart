String terbilang(int number) {
  if (number == 0) return 'nol';

  const satuan = [
    '',
    'satu',
    'dua',
    'tiga',
    'empat',
    'lima',
    'enam',
    'tujuh',
    'delapan',
    'sembilan',
  ];

  String tigaDigit(int n) {
    final ratus = n ~/ 100;
    final sisa = n % 100;
    final puluh = sisa ~/ 10;
    final sat = sisa % 10;

    final parts = <String>[];

    if (ratus > 0) {
      if (ratus == 1) {
        parts.add('seratus');
      } else {
        parts.add('${satuan[ratus]} ratus');
      }
    }

    if (puluh > 0) {
      if (puluh == 1) {
        if (sat == 0) {
          parts.add('sepuluh');
        } else if (sat == 1) {
          parts.add('sebelas');
        } else {
          parts.add('${satuan[sat]} belas');
        }
        return parts.join(' ');
      }
      parts.add('${satuan[puluh]} puluh');
    }

    if (sat > 0) {
      parts.add(satuan[sat]);
    }

    return parts.join(' ');
  }

  final groups = <String>[];
  var temp = number;
  var groupIndex = 0;

  while (temp > 0) {
    final chunk = temp % 1000;
    final chunkText = tigaDigit(chunk);

    if (chunkText.isNotEmpty) {
      switch (groupIndex) {
        case 0:
          groups.add(chunkText);
        case 1:
          groups.add(chunk == 1 ? 'seribu' : '$chunkText ribu');
        case 2:
          groups.add('$chunkText juta');
        case 3:
          groups.add('$chunkText miliar');
        case 4:
          groups.add('$chunkText triliun');
      }
    }

    temp ~/= 1000;
    groupIndex++;
  }

  return groups.reversed.join(' ');
}
