# config/importmap.rb
# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Added libraries
pin "@orchidjs/sifter", to: "https://cdn.jsdelivr.net/npm/@orchidjs/sifter@1.1.0/dist/sifter.min.js" # Try .min.js version
pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/js/tom-select.complete.js" # Using CDN for Tom Select
pin "uuid", to: "https://ga.jspm.io/npm:uuid@9.0.1/dist/esm-browser/index.js" # Using CDN for uuidpin "@orchidjs/unicode-variants", to: "@orchidjs--unicode-variants.js" # @1.1.2
pin "lodash-es", to: "https://ga.jspm.io/npm:lodash-es@4.17.21/lodash.js"