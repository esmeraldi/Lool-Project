using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(lool.Static.Startup))]
namespace lool.Static
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
