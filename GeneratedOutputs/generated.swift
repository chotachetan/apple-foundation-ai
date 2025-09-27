// Input: n = 5
// Output: [[1, 2, 3, 5]]
func fibonacci(n: Int) -> [Int] {
  var result = [Int]()
  for _ in 1...n {
    result.append(Double(i & 1) * (i / 2))
  }
  return result
}