defmodule PlantAidWeb.Helpers do
  import Phoenix.HTML

  def table_opts do
    [
      container: true,
      container_attrs: [class: "overflow-y-auto px-4 sm:overflow-visible sm:px-0"],
      table_attrs: [class: "mt-11 w-[40rem] sm:w-full"],
      tbody_attrs: [
        class:
          "relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
      ],
      tbody_td_attrs: [class: "p-0"],
      tbody_tr_attrs: [class: "relative group hover:bg-zinc-50"],
      thead_th_attrs: [class: "p-0 pb-4 pr-6 font-normal"]
    ]
  end

  def pagination_opts do
    [
      page_links: {:ellipsis, 5},
      pagination_list_attrs: [class: "flex flex-row"]
    ]
  end
end
