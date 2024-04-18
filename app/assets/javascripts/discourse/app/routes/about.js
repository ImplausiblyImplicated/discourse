import { ajax } from "discourse/lib/ajax";
import Category from "discourse/models/category";
import Site from "discourse/models/site";
import DiscourseRoute from "discourse/routes/discourse";
import I18n from "discourse-i18n";

export default DiscourseRoute.extend({
  async model() {
    const result = await ajax("/about.json");
    const users = Object.fromEntries(
      result.users.map((user) => [user.id, user])
    );
    result.categories?.forEach((category) => {
      Site.current().updateCategory(category);
    });

    const yearAgo = moment().locale("en").utc().subtract(1, "year");
    result.about.admins = result.about.admin_ids
      .map((id) => users[id])
      .filter((r) => moment(r.last_seen_at) > yearAgo);
    result.about.moderators = result.about.moderator_ids
      .map((id) => users[id])
      .filter((r) => moment(r.last_seen_at) > yearAgo);
    result.about.category_moderators?.forEach((obj) => {
      obj.category = Category.findById(obj.category_id);
      obj.moderators = obj.moderator_ids.map((id) => users[id]);
    });

    return result.about;
  },

  titleToken() {
    return I18n.t("about.simple_title");
  },
});
