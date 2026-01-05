module.exports = [
    {
      languageOptions: {
        ecmaVersion: 2021,
        sourceType: "commonjs",
        globals: {
          console: "readonly",
          process: "readonly",
          require: "readonly",
          module: "readonly",
          __dirname: "readonly",
        },
      },
      rules: {
        "no-unused-vars": "warn",
        "no-undef": "error",
        "semi": ["error", "always"],
        "quotes": ["warn", "double"],
      },
    },
  ];
