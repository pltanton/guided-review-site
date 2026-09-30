package legacy

import "math"

type FeeCalculator struct {
	percent float64
	min     int64
	max     int64
	exempt  map[string]bool
}

func NewFeeCalculator(percent float64) *FeeCalculator {
	return &FeeCalculator{
		percent: percent,
		min:     10,
		max:     5000,
		exempt:  map[string]bool{},
	}
}

func (c *FeeCalculator) Exempt(account string) {
	c.exempt[account] = true
}

func (c *FeeCalculator) IsExempt(account string) bool {
	return c.exempt[account]
}

func (c *FeeCalculator) Fee(amount int64) int64 {
	if c.percent == 0 {
		return 0
	}
	fee := int64(math.Ceil(float64(amount) * c.percent / 100))
	if fee < c.min {
		fee = c.min
	}
	if fee > c.max {
		fee = c.max
	}
	return fee
}

func (c *FeeCalculator) FeeFor(account string, amount int64) int64 {
	if c.IsExempt(account) {
		return 0
	}
	return c.Fee(amount)
}

type Tier struct {
	UpTo    int64
	Percent float64
}

func TieredFee(amount int64, tiers []Tier) int64 {
	var fee float64
	rest := amount
	var prev int64
	for _, t := range tiers {
		if rest <= 0 {
			break
		}
		span := t.UpTo - prev
		if span > rest {
			span = rest
		}
		fee += float64(span) * t.Percent / 100
		rest -= span
		prev = t.UpTo
	}
	return int64(math.Ceil(fee))
}
