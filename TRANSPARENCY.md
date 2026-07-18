# AI provider environmental transparency

Reviewed July 18, 2026. This is an evidence checklist, not a moral ranking. A check means the linked
first-party material publishes that specific evidence; it does not mean the claim is independently
verified or applies to every model, region, or request. The versioned source of truth used by Quench
is [`provider-transparency.json`](QuenchApp/Resources/provider-transparency.json).

| Provider | Energy per request | Water per request | Method and scope | Lifecycle impacts |
|---|:---:|:---:|:---:|:---:|
| Google Gemini | Yes | Yes | Yes | Not in reviewed disclosure |
| Mistral AI | Not in reviewed disclosure | Yes | Yes | Yes |
| OpenAI / ChatGPT | Yes | Yes | Not in reviewed disclosure | Not in reviewed disclosure |
| Anthropic Claude | Not in reviewed disclosure | Not in reviewed disclosure | Not in reviewed disclosure | Not in reviewed disclosure |

## What each check means

- **Energy per request:** a numerical energy value for a request, prompt, or response.
- **Water per request:** a numerical water-consumption value for a request, prompt, or response.
- **Method and scope:** enough methodology to understand the serving-system boundary and major inclusions.
- **Lifecycle impacts:** upstream hardware, manufacturing, or other lifecycle impacts are included.

## First-party evidence reviewed

- [Google Cloud — Measuring the environmental impact of AI inference](https://cloud.google.com/blog/products/infrastructure/measuring-the-environmental-impact-of-ai-inference/)
- [Mistral AI — Contribution to a global environmental standard](https://mistral.ai/news/our-contribution-to-a-global-environmental-standard-for-ai/)
- [Sam Altman — The Gentle Singularity](https://blog.samaltman.com/the-gentle-singularity)
- [Anthropic — Claude 3 Model Card, sustainability section](https://assets.anthropic.com/m/61e7d27f8c8f5919/original/Claude-3-Model-Card.pdf)

“Not in reviewed disclosure” is deliberately narrower than “does not exist.” Providers can improve
their evidence at any time. Updates require a dated first-party source, a matching JSON change, and
tests; disputed interpretations should be discussed through a public issue or pull request.
