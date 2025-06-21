enum AnswerType {
  none,
  number,
  rightOrder,
  mcq,
}

AnswerType stringToAnswerType(String value) {
  switch (value) {
    case 'AnswerType.none':
      return AnswerType.none;
    case 'AnswerType.number':
      return AnswerType.number;
    case 'AnswerType.rightOrder':
      return AnswerType.rightOrder;
    case 'AnswerType.mcq':
      return AnswerType.mcq;
    default:
      return AnswerType.none;
  }
}
