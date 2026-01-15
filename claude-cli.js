const Anthropic = require('@anthropic-ai/sdk');
const anthropic = new Anthropic({
  apiKey: 'YOUR_API_KEY_HERE',
});

async function askClaude(prompt) {
  const msg = await anthropic.messages.create({
    model: "claude-3-sonnet-20240229",
    max_tokens: 1000,
    messages: [{ role: "user", content: prompt }],
  });
  console.log(msg.content[0].text);
}

askClaude(process.argv[2]);
