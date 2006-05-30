module tango.locale.collation;

private import tango.locale.core;

version (Windows)
  private import tango.locale.win32;
else version (linux)
  private import tango.locale.linux;

public class StringComparer {

  private static StringComparer invariant_;
  private static StringComparer invariantIgnoreCase_;
  private Culture culture_;
  private bool ignoreCase_;

  static this() {
    invariant_ = new StringComparer(Culture.invariantCulture, false);
    invariantIgnoreCase_ = new StringComparer(Culture.invariantCulture, true);
  }

  public this(Culture culture, bool ignoreCase) {
    culture_ = culture;
    ignoreCase_ = ignoreCase;
  }

  public int compare(char[] strA, char[] strB) {
    return nativeMethods.compareString(culture_.id, strA, 0, strA.length, strB, 0, strB.length, ignoreCase_);
  }

  public bool equals(char[] strA, char[] strB) {
    return (compare(strA, strB) == 0);
  }

  public static StringComparer currentCulture() {
    return new StringComparer(Culture.current, false);
  }

  public static StringComparer currentCultureIgnoreCase() {
    return new StringComparer(Culture.current, true);
  }

  public static StringComparer invariantCulture() {
    return invariant_;
  }

  public static StringComparer invariantCultureIgnoreCase() {
    return invariantIgnoreCase_;
  }

}

alias int delegate(char[], char[]) StringComparison;

public class StringSorter {

  private StringComparison comparison_;

  public this(StringComparer comparer = null) {
    if (comparer is null)
      comparer = StringComparer.currentCulture;
    comparison_ = &comparer.compare;
  }

  public this(StringComparison comparison) {
    comparison_ = comparison;
  }

  public void sort(char[][] array) {
    sort(array, 0, array.length);
  }

  public void sort(char[][] array, int index, int count) {

    void qsort(int left, int right) {
      do {
        int i = left, j = right;
        char[] e = array[(i + j) >> 1];

        do {
          while (comparison_(array[i], e) < 0)
            i++;
          while (comparison_(e, array[j]) < 0)
            j--;

          if (i > j)
            break;
          else if (i < j) {
            char[] temp = array[i];
            array[i] = array[j];
            array[j] = temp;
          }

          i++;
          j--;
        } while (i <= j);

        if (j - left <= right - i) {
          if (left < j)
            qsort(left, j);
          left = i;
        }
        else {
          if (i < right)
            qsort(i, right);
          right = j;
        }
      } while (left < right);
    }

    qsort(index, index + (count - 1));
  }

}