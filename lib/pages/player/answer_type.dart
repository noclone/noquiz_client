enum AnswerType {
  none,
  number,
  rightOrder,
}

AnswerType stringToAnswerType(String value) {
  switch (value) {
    case 'AnswerType.none':
      return AnswerType.none;
    case 'AnswerType.number':
      return AnswerType.number;
    case 'AnswerType.rightOrder':
      return AnswerType.rightOrder;
    default:
      return AnswerType.none;
  }
}
