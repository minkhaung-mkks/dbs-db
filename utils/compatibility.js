
export function evaluateRules(rules, selectedParts) {
  const issues = [];

  for (const rule of rules) {
    if (!rule.is_active) continue;

    const config = typeof rule.rule_config === 'string' ? JSON.parse(rule.rule_config) : rule.rule_config;

    if (config.condition) {
      const condPart = selectedParts[config.condition.part];
      if (!condPart) continue;
      const condVal = getSpecField(condPart, config.condition.field);
      if (condVal !== config.condition.equals) continue;
    }

    const result = evaluateRule(config, selectedParts);
    if (result) {
      issues.push({
        rule: rule.rule_number,
        severity: rule.severity,
        message: result.message || formatMessage(rule.message_template, result.a, result.b),
      });
    }
  }

  return issues;
}

function evaluateRule(config, parts) {
  switch (config.type) {
    case 'field_match': return evalFieldMatch(config, parts);
    case 'field_lte': return evalFieldLte(config, parts);
    case 'array_contains': return evalArrayContains(config, parts);
    case 'array_contains_formatted': return evalArrayContainsFormatted(config, parts);
    case 'sum_gte': return evalSumGte(config, parts);
    case 'pair_mismatch': return evalPairMismatch(config, parts);
    default: return null;
  }
}

function getSpecField(part, field) {
  if (!part || !part.specifications) return undefined;
  const specs = typeof part.specifications === 'string' ? JSON.parse(part.specifications) : part.specifications;
  return specs[field];
}

function formatMessage(template, a, b) {
  return template
    .replace(/\{a\}/g, String(a ?? ''))
    .replace(/\{b\}/g, String(b ?? ''));
}


function evalFieldMatch(config, parts) {
  const partA = parts[config.part_a];
  const partB = parts[config.part_b];
  if (!partA || !partB) return null;

  const valA = getSpecField(partA, config.field_a);
  const valB = getSpecField(partB, config.field_b);
  if (valA === undefined || valB === undefined) return null;

  if (valA !== valB) {
    return { a: valA, b: valB };
  }
  return null;
}


function evalFieldLte(config, parts) {
  const partA = parts[config.part_a];
  const partB = parts[config.part_b];
  if (!partA || !partB) return null;

  let valA = getSpecField(partA, config.field_a);
  const valB = getSpecField(partB, config.field_b);

  
  if (config.field_a === '_m2_count') valA = 1;

  if (valA === undefined || valA === null || valB === undefined || valB === null) return null;

  if (Number(valA) > Number(valB)) {
    return { a: valA, b: valB };
  }
  return null;
}


function evalArrayContains(config, parts) {
  const partA = parts[config.part_a];
  const partB = parts[config.part_b];
  if (!partA || !partB) return null;

  const valA = getSpecField(partA, config.field_a);
  const valB = getSpecField(partB, config.field_b);
  if (valA === undefined || !Array.isArray(valB)) return null;

  if (!valB.includes(valA)) {
    return { a: valA, b: valB.join(', ') };
  }
  return null;
}


function evalArrayContainsFormatted(config, parts) {
  const partA = parts[config.part_a];
  const partB = parts[config.part_b];
  if (!partA || !partB) return null;

  const rawVal = getSpecField(partA, config.field_a);
  const valB = getSpecField(partB, config.field_b);
  if (rawVal === undefined || rawVal === null || !Array.isArray(valB)) return null;

  const formatted = config.format.replace('{value}', rawVal);
  if (!valB.includes(formatted)) {
    return { a: formatted, b: valB.join(', ') };
  }
  return null;
}


function evalSumGte(config, parts) {
  const targetPart = parts[config.target_part];
  if (!targetPart) return null;

  const targetVal = getSpecField(targetPart, config.target_field);
  if (targetVal === undefined) return null;

  let sum = 0;
  let hasAny = false;
  for (const sf of config.sum_fields) {
    const part = parts[sf.part];
    if (part) {
      const val = getSpecField(part, sf.field);
      if (val !== undefined && val !== null) {
        sum += Number(val);
        hasAny = true;
      }
    }
  }

  if (!hasAny || sum === 0) return null;

  const recommended = Math.ceil(sum * (config.multiplier || 1));
  if (Number(targetVal) < recommended) {
    return { a: targetVal, b: recommended };
  }
  return null;
}


function evalPairMismatch(config, parts) {
  const partA = parts[config.part_a];
  const partB = parts[config.part_b];
  if (!partA || !partB) return null;

  const valA = getSpecField(partA, config.field_a);
  const valB = getSpecField(partB, config.field_b);
  if (valA === undefined || valB === undefined) return null;

  for (const pair of config.pairs) {
    if (valA === pair.a && valB === pair.b) {
      return { a: valA, b: valB, message: pair.msg };
    }
  }
  return null;
}
