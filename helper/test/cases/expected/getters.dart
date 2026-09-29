class Counter {
  int _count = 0;

  int get count => _count;

  String _label;
  int _step;

  int get step => _step;

  Counter(this._label, this._step);

  String get label => _label;
}
