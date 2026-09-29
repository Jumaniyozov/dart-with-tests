// JSON cannot write a type parameter.
// @not json typeParameterField
class const Wrapper<T>(final T value);

// @not json nestedCollection
class const Grid(final List<List<int>> rows);

// @not json nonStringMapKey
class const ByDay(final Map<int, int> totals);
