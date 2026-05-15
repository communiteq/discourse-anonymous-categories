import { computed } from "@ember/object";
import Category from "discourse/models/category";

export default {
  name: "extend-category-for-anonymous",
  before: "inject-discourse-objects",

  initialize() {
    Category.reopen({
      force_anonymous_posting: computed(
        "custom_fields.force_anonymous_posting",
        {
          get() {
            return this?.custom_fields?.force_anonymous_posting === "true";
          },
        }
      ),
    });
  },
};
